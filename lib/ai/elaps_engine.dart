import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../util.dart';
import 'insights_ml.dart';
import 'intent_data.dart';
import 'intent_model.dart';
import 'text_utils.dart';

class IntentAlt {
  final String id;
  final String label;
  const IntentAlt(this.id, this.label);
}

class AiReply {
  final String text;
  final String intentId;
  final String intentLabel;
  final double confidence;
  final List<IntentAlt> alts; // mbadala kwa kusahihisha (👎)
  final List<String> followUps; // maswali yanayopendekezwa
  final bool learnable; // inatokana na modeli ya ML (inaweza kusahihishwa)
  final bool needsChoice; // modeli haina uhakika: mtumiaji achague nia sahihi
  const AiReply(this.text,
      {this.intentId = 'entity',
      this.intentLabel = '',
      this.confidence = 1,
      this.alts = const [],
      this.followUps = const [],
      this.learnable = false,
      this.needsChoice = false});
}

class _Ent {
  final bool isKanda;
  final String name;
  final Kanda kanda;
  const _Ent(this.isKanda, this.name, this.kanda);
}

class _J {
  final String name;
  final Kanda kanda;
  final int amount;
  const _J(this.name, this.kanda, this.amount);
}

class _Period {
  final String label;
  final DateTime start;
  final DateTime end;
  const _Period(this.label, this.start, this.end);
}

/// ELAPS AI: inaelewa Kiswahili (na Kiingereza), inatambua nia kwa ML
/// (Naive Bayes + Deep Neural Network), inatambua majina/tarehe/viasi,
/// inachambua data kwa takwimu/ML, na inajifunza kutokana na maoni yako.
/// Kila kitu kinaendeshwa kwenye kifaa -- hakuna intaneti inayohitajika.
class ElapsEngine {
  static ElapsEngine? _inst;
  static ElapsEngine shared(AppState app) => _inst ??= ElapsEngine._(app);

  final AppState app;
  final IntentModel model = IntentModel();
  final List<(String, String)> _learned = [];
  Future<void>? _initF;
  _Ent? _last; // muktadha: jina la mwisho lililozungumziwa

  ElapsEngine._(this.app);

  bool get started => model.sampleCount > 0;
  bool get neuralReady => model.nnReady;

  Future<void> init() => _initF ??= _init();

  Future<void> _init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('elaps_learn_v1');
      if (raw != null) {
        for (final e in jsonDecode(raw) as List) {
          final l = e as List;
          _learned.add((l[0] as String, l[1] as String));
        }
      }
    } catch (_) {}
    await model.init(_learned);
  }

  /// Kujifunza kutokana na maoni (👍 / 👎 + chaguo sahihi).
  Future<void> learn(String question, String intentId) async {
    await model.learn(question, intentId);
    _learned.add((question, intentId));
    if (_learned.length > 300) _learned.removeAt(0);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('elaps_learn_v1',
          jsonEncode([for (final e in _learned) [e.$1, e.$2]]));
    } catch (_) {}
  }

  int get learnedCount => _learned.length;

  // ------------------------------------------------------------------
  // Msaidizi wa data
  // ------------------------------------------------------------------
  List<_J> get _js => [
        for (final k in kSeedKanda)
          for (final j in k.jumuiya)
            _J(j, k, app.jumuiyaFee[AppState.jKey(k.name, j)] ?? 0)
      ];

  String _tsh(int n) => 'TSh ${fmt(n)}';
  String _pct(num a, num b) => b <= 0 ? '0%' : '${(a * 100 / b).toStringAsFixed(1)}%';
  String _line(Receipt r) =>
      '• No. ${r.noText}: ${r.isKanda ? 'Ada ya ${r.kanda}' : r.jumuiya} ${_tsh(r.amount)} (${dateText(r.date)})';

  // ------------------------------------------------------------------
  // Utambuzi wa majina (kwa kukisia makosa ya uandishi)
  // ------------------------------------------------------------------
  static const _stop = {
    'mt', 'wt', 'wat', 'na', 'wa', 'de', 'ya', 'la', 'kwa', 'ni', 'je',
    'kanda', 'jumuiya', 'jumla', 'ada', 'kiasi', 'gani', 'nani', 'yake',
  };
  final Map<String, List<String>> _tokCache = {};

  List<String> _nameTokens(String name) => _tokCache.putIfAbsent(
      name,
      () => splitWords(normalizeText(name))
          .where((w) => w.length >= 3 && !_stop.contains(w))
          .toList());

  double _score(List<String> q, String name) {
    final tk = _nameTokens(name);
    if (tk.isEmpty) return 0;
    final hit = tk.where((t) => q.any((w) => fuzzyEq(w, t))).length;
    if (hit == 0) return 0;
    final ratio = hit / tk.length;
    if (ratio < 0.5) return 0;
    return ratio + hit / 100;
  }

  List<_Ent> _findEntities(String n) {
    final q = splitWords(n).where((w) => w.length >= 3 && !_stop.contains(w)).toList();
    if (q.isEmpty) return [];
    final c = <(double, _Ent)>[];
    for (final k in kSeedKanda) {
      final sk = _score(q, k.name);
      if (sk > 0) c.add((sk, _Ent(true, k.name, k)));
      for (final j in k.jumuiya) {
        final sj = _score(q, j);
        if (sj > 0) c.add((sj, _Ent(false, j, k)));
      }
    }
    if (c.isEmpty) return [];
    var best = 0.0;
    for (final e in c) {
      if (e.$1 > best) best = e.$1;
    }
    final cut = best >= 0.99 ? 0.99 : best - 1e-9;
    final out = [for (final e in c) if (e.$1 >= cut) e.$2];
    return out.take(3).toList();
  }

  // ------------------------------------------------------------------
  // Tarehe / vipindi
  // ------------------------------------------------------------------
  _Period? _parsePeriod(String n) {
    final w = splitWords(n).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    if (w.contains('leo') || w.contains('today')) {
      return _Period('leo', today, today.add(const Duration(days: 1)));
    }
    if (w.contains('jana') || w.contains('yesterday')) {
      return _Period('jana', today.subtract(const Duration(days: 1)), today);
    }
    if (w.contains('wiki') && (w.contains('iliyopita') || w.contains('jana'))) {
      return _Period('wiki iliyopita', monday.subtract(const Duration(days: 7)), monday);
    }
    if (w.contains('wiki') && (w.contains('hii') || w.contains('huu'))) {
      return _Period('wiki hii', monday, monday.add(const Duration(days: 7)));
    }
    if (w.contains('mwezi') && (w.contains('uliopita') || w.contains('jana'))) {
      return _Period('mwezi uliopita', DateTime(today.year, today.month - 1, 1),
          DateTime(today.year, today.month, 1));
    }
    if (w.contains('mwezi') && (w.contains('huu') || w.contains('hii'))) {
      return _Period('mwezi huu', DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 1));
    }
    if (w.contains('mwaka') && (w.contains('huu') || w.contains('hii'))) {
      return _Period('mwaka huu', DateTime(today.year, 1, 1), DateTime(today.year + 1, 1, 1));
    }
    return null;
  }

  String _periodAnswer(_Period p) {
    final rs = app.receipts
        .where((r) => !r.date.isBefore(p.start) && r.date.isBefore(p.end))
        .toList();
    if (rs.isEmpty) return 'Hakuna taarifa zilizoingizwa ${p.label}.';
    final sum = rs.fold<int>(0, (a, r) => a + r.amount);
    final kSum = rs.where((r) => r.isKanda).fold<int>(0, (a, r) => a + r.amount);
    final by = <String, int>{};
    for (final r in rs) {
      final key = r.isKanda ? 'Ada ya ${r.kanda}' : r.jumuiya;
      by[key] = (by[key] ?? 0) + r.amount;
    }
    final top = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return 'Makusanyo ya ${p.label}: ${_tsh(sum)} kutokana na taarifa ${rs.length} '
        '(Kanda ${_tsh(kSum)}, Jumuiya ${_tsh(sum - kSum)}).\n'
        'Walioongoza:\n${top.take(3).map((e) => '• ${e.key} — ${_tsh(e.value)}').join('\n')}';
  }

  // ------------------------------------------------------------------
  // Vichujio vya kiasi: "zaidi ya 50000", "chini ya elfu 30"
  // ------------------------------------------------------------------
  String? _amountAnswer(String raw, String n) {
    final amt = parseAmount(raw);
    if (amt == null) return null;
    final w = splitWords(n).toSet();
    final above = w.contains('zaidi') || w.contains('juu') || w.contains('over') || w.contains('above');
    final below = w.contains('chini') || w.contains('pungufu') || w.contains('under') || w.contains('below');
    final eq = w.contains('sawa') || w.contains('tsh');
    if (!above && !below && !eq) return null;
    final kandaScope = w.contains('kanda') && !w.contains('jumuiya');
    final items = kandaScope
        ? [for (final k in kSeedKanda) (k.name, app.kandaTotal(k))]
        : [for (final j in _js) (j.name, j.amount)];
    final noun = kandaScope ? 'Kanda' : 'Jumuiya';
    final sel = items.where((e) {
      if (above) return e.$2 > amt;
      if (below) return e.$2 > 0 && e.$2 < amt;
      return e.$2 == amt;
    }).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final cond = above ? 'zaidi ya' : (below ? 'chini ya' : 'sawa na');
    if (sel.isEmpty) return 'Hakuna $noun yenye kiasi $cond ${_tsh(amt)}.';
    return '$noun zenye kiasi $cond ${_tsh(amt)} (${sel.length}):\n'
        '${sel.take(12).map((e) => '• ${e.$1} — ${_tsh(e.$2)}').join('\n')}'
        '${sel.length > 12 ? '\n… na ${sel.length - 12} nyingine.' : ''}';
  }

  // ------------------------------------------------------------------
  // Majibu ya jina (Jumuiya / Kanda)
  // ------------------------------------------------------------------
  String _entityAnswer(_Ent e, String intent) {
    final k = e.kanda;
    if (!e.isKanda) {
      final j = e.name;
      final list = app.entriesFor(k.name, j);
      final amount = app.jumuiyaFee[AppState.jKey(k.name, j)] ?? 0;
      if (intent == 'recent' && list.isNotEmpty) {
        return 'Taarifa za $j (mpya kwanza):\n${list.take(5).map(_line).join('\n')}';
      }
      final kf = app.kandaFee[k.name] ?? 0;
      final kandaPart =
          'Kanda yake ni ${k.name} (Ada Kanda: ${kf > 0 ? _tsh(kf) : 'haijajazwa'}, jumla ya Kanda ${_tsh(app.kandaTotal(k))}).';
      if (list.isEmpty) return '$j bado haijaweka ada. $kandaPart';
      final ranked = _js.where((x) => x.amount > 0).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final pos = ranked.indexWhere((x) => x.name == j) + 1;
      final last = list.first;
      return '$j: jumla ${_tsh(amount)} kutokana na taarifa ${list.length}. '
          'Ya mwisho: ${dateText(last.date)} (${_tsh(last.amount)}). '
          'Nafasi ya $pos kati ya ${ranked.length} zilizolipa (${_pct(amount, app.totalJumuiya)} ya ada za Jumuiya). $kandaPart';
    }
    final rows = [for (final j in k.jumuiya) _J(j, k, app.jumuiyaFee[AppState.jKey(k.name, j)] ?? 0)];
    final paid = rows.where((r) => r.amount > 0).toList();
    final unpaid = rows.where((r) => r.amount <= 0).map((r) => r.name).toList();
    if (intent == 'unpaid') {
      return unpaid.isEmpty
          ? 'Jumuiya zote za ${k.name} zimeweka ada.'
          : 'Jumuiya za ${k.name} ambazo hazijaweka ada (${unpaid.length}): ${unpaid.join(', ')}.';
    }
    if (intent == 'paid') {
      return paid.isEmpty
          ? 'Hakuna Jumuiya ya ${k.name} iliyolipa bado.'
          : 'Zilizolipa kwenye ${k.name} (${paid.length}/${rows.length}):\n${(paid..sort((a, b) => b.amount.compareTo(a.amount))).map((r) => '• ${r.name} — ${_tsh(r.amount)}').join('\n')}';
    }
    if (intent == 'rank') {
      final s = [...rows]..sort((a, b) => b.amount.compareTo(a.amount));
      return 'Mpangilio wa Jumuiya za ${k.name}:\n${[for (var i = 0; i < s.length; i++) '${i + 1}. ${s[i].name} — ${_tsh(s[i].amount)}'].join('\n')}';
    }
    if (intent == 'recent') {
      final list = [
        ...app.entriesFor(k.name, null),
        for (final j in k.jumuiya) ...app.entriesFor(k.name, j)
      ]..sort((a, b) => b.no.compareTo(a.no));
      return list.isEmpty
          ? 'Hakuna taarifa za ${k.name} bado.'
          : 'Taarifa za karibuni za ${k.name}:\n${list.take(5).map(_line).join('\n')}';
    }
    final kf = app.kandaFee[k.name] ?? 0;
    final jSum = rows.fold<int>(0, (a, r) => a + r.amount);
    return '${k.name}: Ada Kanda ${kf > 0 ? _tsh(kf) : 'haijajazwa'}; '
        'Jumuiya zilizolipa ${paid.length}/${rows.length}; jumla ya Jumuiya ${_tsh(jSum)}; '
        'jumla kuu ${_tsh(app.kandaTotal(k))} (${_pct(app.kandaTotal(k), app.total)} ya makusanyo yote).'
        '${unpaid.isEmpty ? '' : ' Hawajalipa: ${unpaid.join(', ')}.'}';
  }

  String _compare(List<_Ent> es) {
    String one(_Ent e) {
      if (!e.isKanda) {
        final a = app.jumuiyaFee[AppState.jKey(e.kanda.name, e.name)] ?? 0;
        return '• ${e.name}: ${_tsh(a)} (taarifa ${app.entriesFor(e.kanda.name, e.name).length}, Kanda ${e.kanda.name})';
      }
      final t = app.kandaTotal(e.kanda);
      final p = e.kanda.jumuiya
          .where((j) => (app.jumuiyaFee[AppState.jKey(e.kanda.name, j)] ?? 0) > 0)
          .length;
      return '• ${e.name}: jumla ${_tsh(t)} (Jumuiya zilizolipa $p/${e.kanda.jumuiya.length})';
    }

    final buf = StringBuffer('Ulinganisho:\n${es.map(one).join('\n')}');
    if (es.every((e) => e.isKanda == es.first.isKanda) && es.length == 2) {
      int val(_Ent e) => e.isKanda
          ? app.kandaTotal(e.kanda)
          : (app.jumuiyaFee[AppState.jKey(e.kanda.name, e.name)] ?? 0);
      final a = val(es[0]), b = val(es[1]);
      if (a == b) {
        buf.write('\nZinalingana kwa kiasi.');
      } else {
        final w = a > b ? es[0] : es[1];
        buf.write('\n${w.name} inaongoza kwa ${_tsh((a - b).abs())}.');
      }
    }
    return buf.toString();
  }

  // ------------------------------------------------------------------
  // Majibu ya nia (intents)
  // ------------------------------------------------------------------
  String _answer(String intent, String raw, String n) {
    final js = _js;
    final unpaid = js.where((x) => x.amount <= 0).toList();
    switch (intent) {
      case 'greet':
        final h = DateTime.now().hour;
        final g = h < 12 ? 'Habari za asubuhi' : (h < 16 ? 'Habari za mchana' : 'Habari za jioni');
        return '$g! Mimi ni ELAPS AI. Hadi sasa makusanyo ni ${_tsh(app.total)}/=, '
            'Jumuiya ${app.paidJumuiya}/${app.jumuiyaCount} zimeweka ada. '
            'Uliza chochote, mfano: "hajalipa", "Kanda ya Hellena" au "nipe muhtasari".';
      case 'thanks':
        return 'Karibu sana! Nipo hapa ukihitaji kitu kingine.';
      case 'bye':
        return 'Kwaheri! Usisahau kuhifadhi nakala ya records zako (Export).';
      case 'who':
        return 'Mimi ni ELAPS AI, msaidizi wa mfumo huu wa makusanyo. Ninaelewa Kiswahili na Kiingereza, '
            'na ninafanya kazi kwenye kifaa chako bila intaneti.\n'
            'Ndani yangu kuna: (1) Naive Bayes na (2) mtandao wa neva wenye tabaka mbili fiche (deep neural network) '
            'vinavyotambua unachomaanisha; (3) regression kwa utabiri, (4) K-Means kwa makundi ya viwango, '
            '(5) z-score/IQR kwa kugundua hitilafu.\n'
            'Ukibonyeza 👎 na kuchagua nilichostahili kuelewa, najifunza na kuhifadhi (sasa nimejifunza mara $learnedCount).';
      case 'help':
        return 'Naweza kujibu kuhusu makusanyo yako. Mifano:\n'
            '• "Benedict amelipa kiasi gani?" / "Kanda ya Hellena"\n'
            '• "Hajalipa" / "Waliolipa" / "Kanda inayoongoza" / "Tano bora"\n'
            '• "Makusanyo ya leo", "wiki hii", "mwezi uliopita"\n'
            '• "Jumuiya zenye zaidi ya 50000"\n'
            '• "Linganisha Pio na Kizito"\n'
            '• "Utabiri", "Kagua makosa", "Makundi ya viwango", "Muhtasari", "Ushauri"';
      case 'offtopic':
        return 'Hilo liko nje ya kazi yangu: nimefundishwa kuhusu makusanyo ya Kanda na Jumuiya. '
            'Jaribu: "jumla", "hajalipa", "Kanda ya Hellena" au "nipe muhtasari".';
      case 'total':
        return 'Jumla ya makusanyo ni ${_tsh(app.total)}/=.\n'
            '• Kanda: ${_tsh(app.totalKanda)} (${_pct(app.totalKanda, app.total)})\n'
            '• Jumuiya: ${_tsh(app.totalJumuiya)} (${_pct(app.totalJumuiya, app.total)})\n'
            'Jumuiya zilizoweka ada: ${app.paidJumuiya}/${app.jumuiyaCount}.';
      case 'unpaid':
        if (unpaid.isEmpty) return 'Jumuiya zote zimeweka ada.';
        final lines = [
          for (final k in kSeedKanda)
            if (unpaid.any((x) => x.kanda.name == k.name))
              '• ${k.name}: ${unpaid.where((x) => x.kanda.name == k.name).map((x) => x.name).join(', ')}'
        ];
        return 'Jumuiya ${unpaid.length} hazijaweka ada:\n${lines.join('\n')}';
      case 'paid':
        final paid = js.where((x) => x.amount > 0).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
        if (paid.isEmpty) return 'Hakuna Jumuiya iliyolipa bado.';
        return 'Zilizolipa ${paid.length}/${js.length}:\n'
            '${paid.take(12).map((x) => '• ${x.name} — ${_tsh(x.amount)}').join('\n')}'
            '${paid.length > 12 ? '\n… na ${paid.length - 12} nyingine.' : ''}';
      case 'rank':
        return _rank(n);
      case 'recent':
        if (app.receipts.isEmpty) return 'Bado hakuna taarifa zilizohifadhiwa.';
        final last = (app.receipts.toList()..sort((a, b) => b.no.compareTo(a.no))).take(5);
        return 'Taarifa za karibuni:\n${last.map(_line).join('\n')}';
      case 'today':
        final now = DateTime.now();
        final t0 = DateTime(now.year, now.month, now.day);
        return _periodAnswer(_Period('leo', t0, t0.add(const Duration(days: 1))));
      case 'count':
        final kc = app.receipts.where((r) => r.isKanda).length;
        return 'Taarifa zote: ${app.receipts.length} (za Jumuiya ${app.receipts.length - kc}, za Kanda $kc).';
      case 'average':
        final avPaid = js.where((x) => x.amount > 0).toList();
        final jr = app.receipts.where((r) => !r.isKanda).toList();
        if (app.receipts.isEmpty) return 'Bado hakuna data ya kukokotoa wastani.';
        final buf = StringBuffer();
        if (avPaid.isNotEmpty) {
          buf.writeln('• Wastani kwa Jumuiya iliyolipa: ${_tsh((app.totalJumuiya / avPaid.length).round())}');
        }
        if (jr.isNotEmpty) {
          buf.writeln('• Wastani kwa risiti ya Jumuiya: ${_tsh((app.totalJumuiya / jr.length).round())}');
        }
        buf.write('• Wastani wa jumla kwa Kanda: ${_tsh((app.total / kSeedKanda.length).round())}');
        return buf.toString();
      case 'kanda_fee':
        return 'Hali ya ada za Kanda:\n${kSeedKanda.map((k) {
          final f = app.kandaFee[k.name] ?? 0;
          return '• ${k.name}: ${f > 0 ? _tsh(f) : 'haijajazwa'}';
        }).join('\n')}';
      case 'anomaly':
        final a = detectAnomalies(app);
        if (a.isEmpty) {
          return 'Sijaona hitilafu yoyote. Nimekagua viwango visivyo vya kawaida (z-score/IQR) na rekodi zilizojirudia kati ya taarifa ${app.receipts.length}.';
        }
        return 'Nimegundua mambo ${a.length} ya kuhakiki:\n${a.map((e) => '• $e').join('\n')}';
      case 'forecast':
        final f = forecast(app);
        if (f == null) {
          return 'Data bado haitoshi kwa utabiri. Inahitaji siku 3 au zaidi zenye taarifa (sasa ni ${app.receipts.map((r) => '${r.date.year}-${r.date.month}-${r.date.day}').toSet().length}).';
        }
        final fcPaid = js.where((x) => x.amount > 0).length;
        final potential = fcPaid == 0 ? 0 : (app.totalJumuiya / fcPaid * unpaid.length).round();
        return 'Makadirio (linear regression, siku ${f.days} zenye data):\n'
            '• Kasi ya wastani: ≈ ${_tsh(f.perDay.round())} kwa siku\n'
            '• Baada ya siku 7: ≈ ${_tsh(f.in7.round())}\n'
            '• Baada ya siku 30: ≈ ${_tsh(f.in30.round())}\n'
            '${potential > 0 ? '• Jumuiya ${unpaid.length} zilizobaki zikilipa wastani, zinaweza kuongeza ≈ ${_tsh(potential)}\n' : ''}'
            '${f.r2 < 0.6 ? 'Tahadhari: mwelekeo si imara (R² ${f.r2.toStringAsFixed(2)}); makadirio yanaweza kuwa mbali.' : 'Uhakika wa mstari: R² ${f.r2.toStringAsFixed(2)}.'}';
      case 'segments':
        final seg = segmentJumuiya([for (final j in js) (j.name, j.amount)]);
        if (seg == null) return 'Data bado haitoshi kugawa makundi (inahitaji viwango tofauti vya angalau aina 3).';
        return 'Makundi ya Jumuiya (K-Means):\n${seg.reversed.map((s) => '• ${s.label} (wastani ${_tsh(s.center.round())}): ${s.members.take(6).map((m) => m.$1).join(', ')}${s.members.length > 6 ? ' +${s.members.length - 6}' : ''}').join('\n')}';
      case 'summary':
        final top = app.topKanda();
        final an = detectAnomalies(app).length;
        final fs = forecast(app);
        return 'Muhtasari:\n'
            '• Jumla: ${_tsh(app.total)} (Kanda ${_tsh(app.totalKanda)}, Jumuiya ${_tsh(app.totalJumuiya)})\n'
            '• Jumuiya zilizolipa: ${app.paidJumuiya}/${app.jumuiyaCount}; hazijalipa: ${unpaid.length}\n'
            '${top != null ? '• Kanda inayoongoza: ${top.name} (${_tsh(app.kandaTotal(top))})\n' : ''}'
            '• Taarifa: ${app.receipts.length}; hitilafu zinazotiliwa shaka: $an\n'
            '${fs != null ? '• Mwelekeo: ≈ ${_tsh(fs.perDay.round())} kwa siku' : '• Mwelekeo: data bado haitoshi'}';
      case 'advice':
        return 'Ushauri:\n${app.tips().map((t) => '• ${t.text}').join('\n')}';
    }
    return 'Sijaelewa swali hilo.';
  }

  String _rank(String n) {
    final w = splitWords(n).toSet();
    final asc = ['mwisho', 'chini', 'dhaifu', 'ndogo', 'kidogo', 'nyuma', 'least', 'lowest', 'bottom']
        .any(w.contains);
    final topN = parseTopN(n);
    final jScope = w.contains('jumuiya') || (topN != null && !w.contains('kanda'));
    final items = jScope
        ? [for (final j in _js) (j.name, j.amount)]
        : [for (final k in kSeedKanda) (k.name, app.kandaTotal(k))];
    items.sort((a, b) => asc ? a.$2.compareTo(b.$2) : b.$2.compareTo(a.$2));
    if (items.every((e) => e.$2 == 0)) return 'Bado hakuna ada zilizohifadhiwa.';
    final take = topN ?? (jScope ? 5 : items.length);
    final shown = items.take(take).toList();
    final title = '${jScope ? 'Jumuiya' : 'Kanda'} ${asc ? 'zenye kiasi kidogo zaidi' : 'zinazoongoza'}';
    return '$title:\n${[for (var i = 0; i < shown.length; i++) '${i + 1}. ${shown[i].$1} — ${_tsh(shown[i].$2)}'].join('\n')}';
  }

  static const _follow = <String, List<String>>{
    'greet': ['Jumla', 'Hajalipa', 'Muhtasari'],
    'total': ['Kanda inayoongoza', 'Hajalipa', 'Utabiri'],
    'unpaid': ['Waliolipa', 'Ada za Kanda', 'Ushauri'],
    'paid': ['Hajalipa', 'Tano bora', 'Wastani'],
    'rank': ['Hajalipa', 'Makundi ya viwango', 'Jumla'],
    'recent': ['Makusanyo ya leo', 'Kagua makosa', 'Jumla'],
    'today': ['Wiki hii', 'Karibuni', 'Jumla'],
    'count': ['Karibuni', 'Wastani', 'Jumla'],
    'average': ['Makundi ya viwango', 'Utabiri', 'Jumla'],
    'kanda_fee': ['Hajalipa', 'Ushauri', 'Jumla'],
    'anomaly': ['Karibuni', 'Muhtasari', 'Jumla'],
    'forecast': ['Hajalipa', 'Muhtasari', 'Jumla'],
    'segments': ['Tano bora', 'Hajalipa', 'Utabiri'],
    'summary': ['Hajalipa', 'Utabiri', 'Kagua makosa'],
    'advice': ['Hajalipa', 'Kagua makosa', 'Muhtasari'],
    'help': ['Jumla', 'Hajalipa', 'Muhtasari'],
    'who': ['Msaada', 'Jumla', 'Muhtasari'],
    'entity': ['Hajalipa', 'Kanda inayoongoza', 'Karibuni'],
    'period': ['Jumla', 'Karibuni', 'Hajalipa'],
    'offtopic': ['Msaada', 'Jumla', 'Muhtasari'],
  };

  // ------------------------------------------------------------------
  // Mlango mkuu
  // ------------------------------------------------------------------
  AiReply ask(String raw, {String? forceIntent}) {
    final q = raw.trim();
    final n = normalizeText(q);
    if (n.isEmpty) {
      return AiReply(_answer('help', q, n), followUps: _follow['help']!);
    }
    if (!started) {
      return const AiReply('ELAPS AI inajiandaa (inafundisha modeli)... jaribu tena baada ya sekunde chache.');
    }

    final scores = model.predict(q);
    final top = scores.first;
    final intent = forceIntent ?? top.id;
    final conf = forceIntent != null ? 1.0 : top.p;
    final alts = [
      for (final s in scores.where((s) => s.id != intent && s.id != 'offtopic').take(3))
        IntentAlt(s.id, kIntentLabels[s.id] ?? s.id)
    ];
    AiReply mlReply(String id, String text) => AiReply(text,
        intentId: id,
        intentLabel: kIntentLabels[id] ?? id,
        confidence: conf,
        alts: alts,
        followUps: _follow[id] ?? const [],
        learnable: true);
    AiReply ruleReply(String id, String text) => AiReply(text,
        intentId: id, followUps: _follow[id] ?? const [], alts: alts);

    final w = splitWords(n).toSet();
    var ents = intent == 'thanks' || intent == 'bye' ? <_Ent>[] : _findEntities(n);
    const pronouns = {'yake', 'huyo', 'hiyo', 'hizo', 'yao', 'wake', 'wale', 'naye'};
    if (ents.isEmpty && _last != null && w.any(pronouns.contains)) ents = [_last!];

    // 1) Kiasi (zaidi ya / chini ya ...)
    if (ents.isEmpty && forceIntent == null) {
      final a = _amountAnswer(raw, n);
      if (a != null) return ruleReply('entity', a);
    }

    // 2) Majina
    if (ents.length >= 2) {
      return ruleReply('entity', _compare(ents));
    }
    if (ents.length == 1) {
      _last = ents.first;
      return ruleReply('entity', _entityAnswer(ents.first, intent));
    }

    // 3) Vipindi vya muda
    final period = _parsePeriod(n);
    const periodOk = {'total', 'recent', 'today', 'count', 'average', 'paid', 'summary'};
    if (period != null && (periodOk.contains(intent) || conf < 0.5) && forceIntent == null) {
      return ruleReply('period', _periodAnswer(period));
    }

    // 4) Kutokuwa na uhakika -> uliza kwa upole badala ya kubahatisha
    if (conf < 0.5) {
      final opts = scores.take(3).map((s) => IntentAlt(s.id, kIntentLabels[s.id] ?? s.id)).toList();
      return AiReply(
        'Samahani, sijaelewa vizuri. Je, ulimaanisha mojawapo ya haya?\n'
        '${opts.map((o) => '• ${o.label}').join('\n')}\n'
        'Bonyeza 👎 kisha uchague, na nitajifunza. Au andika "msaada" kuona mifano.',
        intentId: top.id,
        intentLabel: kIntentLabels[top.id] ?? top.id,
        confidence: conf,
        alts: opts,
        followUps: const ['Msaada', 'Jumla', 'Hajalipa'],
        learnable: true,
        needsChoice: true,
      );
    }
    return mlReply(intent, _answer(intent, q, n));
  }
}
