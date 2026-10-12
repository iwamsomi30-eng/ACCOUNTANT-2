import 'dart:math' as math;
import '../state/app_state.dart';
import '../util.dart';

/// Uchambuzi wa data ya mfumo kwa mbinu za ML/takwimu (zinaendeshwa kwenye kifaa).

double _mean(List<double> v) =>
    v.isEmpty ? 0 : v.fold<double>(0, (a, b) => a + b) / v.length;

double _std(List<double> v) {
  if (v.length < 2) return 0;
  final m = _mean(v);
  return math.sqrt(v.fold<double>(0, (a, b) => a + (b - m) * (b - m)) / v.length);
}

double _quantile(List<double> sorted, double q) {
  if (sorted.isEmpty) return 0;
  final pos = (sorted.length - 1) * q;
  final lo = pos.floor();
  final hi = pos.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

String _who(Receipt r) => r.isKanda ? 'Ada ya ${r.kanda}' : r.jumuiya;

/// 1) Ugunduzi wa hitilafu: z-score + IQR (viwango visivyo vya kawaida)
///    na ugunduzi wa rekodi zilizojirudia (jina, kiasi na siku vilevile).
List<String> detectAnomalies(AppState app) {
  final out = <String>[];
  final rs = app.receipts;
  if (rs.isEmpty) return out;

  for (final isK in [false, true]) {
    final group = rs.where((r) => r.isKanda == isK).toList();
    if (group.length < 6) continue;
    final amounts = group.map((r) => r.amount.toDouble()).toList();
    final m = _mean(amounts);
    final sd = _std(amounts);
    final sorted = [...amounts]..sort();
    final q1 = _quantile(sorted, .25);
    final q3 = _quantile(sorted, .75);
    final fence = q3 + 3 * (q3 - q1);
    for (final r in group) {
      final z = sd > 0 ? (r.amount - m) / sd : 0;
      if (z > 2.5 || (q3 > q1 && r.amount > fence)) {
        out.add(
            'No. ${r.noText} (${_who(r)}, ${dateText(r.date)}): TSh ${fmt(r.amount)} '
            'ni kubwa kuliko kawaida (wastani wa ${isK ? 'Kanda' : 'Jumuiya'} ni TSh ${fmt(m.round())}). Hakiki kama hakuna zero ya ziada.');
      }
    }
  }

  final seen = <String, List<Receipt>>{};
  for (final r in rs) {
    final key =
        '${r.type}|${r.kanda}|${r.jumuiya}|${r.amount}|${r.date.year}-${r.date.month}-${r.date.day}';
    seen.putIfAbsent(key, () => []).add(r);
  }
  for (final e in seen.values) {
    if (e.length > 1) {
      final r = e.first;
      out.add(
          '${_who(r)}: kuna rekodi ${e.length} zenye kiasi sawa (TSh ${fmt(r.amount)}) '
          'siku ile ile ${dateText(r.date)} (No. ${e.map((x) => x.noText).join(', ')}). Huenda ni marudio.');
    }
  }
  return out;
}

class Forecast {
  final double perDay; // kasi ya makusanyo kwa siku (mteremko wa regression)
  final double in7;
  final double in30;
  final double r2; // ubora wa mstari (0..1)
  final int days; // siku zenye data
  const Forecast(this.perDay, this.in7, this.in30, this.r2, this.days);
}

/// 2) Utabiri: Linear Regression (least squares) ya jumla iliyokusanywa dhidi ya siku.
Forecast? forecast(AppState app) {
  if (app.receipts.isEmpty) return null;
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final perDay = <DateTime, int>{};
  for (final r in app.receipts) {
    final d = day(r.date);
    perDay[d] = (perDay[d] ?? 0) + r.amount;
  }
  final days = perDay.keys.toList()..sort();
  if (days.length < 3) return null;
  final start = days.first;
  final xs = <double>[];
  final ys = <double>[];
  var cum = 0;
  for (final d in days) {
    cum += perDay[d]!;
    xs.add(d.difference(start).inDays.toDouble());
    ys.add(cum.toDouble());
  }
  final mx = _mean(xs);
  final my = _mean(ys);
  var sxx = 0.0, sxy = 0.0, syy = 0.0;
  for (var i = 0; i < xs.length; i++) {
    sxx += (xs[i] - mx) * (xs[i] - mx);
    sxy += (xs[i] - mx) * (ys[i] - my);
    syy += (ys[i] - my) * (ys[i] - my);
  }
  if (sxx == 0) return null;
  final a = sxy / sxx;
  final b = my - a * mx;
  final r2 = syy == 0 ? 0.0 : (sxy * sxy) / (sxx * syy);
  final nowX = day(DateTime.now()).difference(start).inDays.toDouble();
  final cur = app.total.toDouble();
  double at(double x) => math.max(cur, a * x + b);
  return Forecast(
      math.max(0, a), at(nowX + 7), at(nowX + 30), r2, days.length);
}

class Segment {
  final String label;
  final double center;
  final List<(String, int)> members;
  const Segment(this.label, this.center, this.members);
}

/// 3) Makundi: K-Means (k=3, 1-D) ya jumla ya kila Jumuiya -> Juu / Kati / Chini.
List<Segment>? segmentJumuiya(List<(String, int)> items) {
  if (items.length < 6) return null;
  final vals = items.map((e) => e.$2.toDouble()).toList();
  if (vals.toSet().length < 3) return null;
  final sorted = [...vals]..sort();
  var centers = [sorted.first, _quantile(sorted, .5), sorted.last];
  var assign = List<int>.filled(vals.length, 0);
  for (var it = 0; it < 30; it++) {
    var changed = false;
    for (var i = 0; i < vals.length; i++) {
      var best = 0;
      var bd = double.infinity;
      for (var c = 0; c < 3; c++) {
        final d = (vals[i] - centers[c]).abs();
        if (d < bd) {
          bd = d;
          best = c;
        }
      }
      if (assign[i] != best) {
        assign[i] = best;
        changed = true;
      }
    }
    final nc = [...centers];
    for (var c = 0; c < 3; c++) {
      final m = [for (var i = 0; i < vals.length; i++) if (assign[i] == c) vals[i]];
      if (m.isNotEmpty) nc[c] = _mean(m);
    }
    centers = nc;
    if (!changed) break;
  }
  const labels = ['Chini', 'Kati', 'Juu'];
  final order = [0, 1, 2]..sort((a, b) => centers[a].compareTo(centers[b]));
  final out = <Segment>[];
  for (var rank = 0; rank < 3; rank++) {
    final c = order[rank];
    final mem = [
      for (var i = 0; i < items.length; i++)
        if (assign[i] == c) items[i]
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    out.add(Segment(labels[rank], centers[c], mem));
  }
  return out;
}
