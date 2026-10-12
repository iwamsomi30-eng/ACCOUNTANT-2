import 'dart:math' as math;
import 'dart:typed_data';
import 'intent_data.dart';
import 'text_utils.dart';

/// Mfano mmoja wa mafunzo: swali + nia yake.
class Sample {
  final String text;
  final String intent;
  final double weight;
  final List<int> x; // features (sparse)
  Sample(this.text, this.intent, this.weight, int dim)
      : x = featurize(text, dim);
}

List<double> _softmax(List<double> z) {
  var m = z.reduce(math.max);
  final e = [for (final v in z) math.exp(v - m)];
  final s = e.fold<double>(0, (a, b) => a + b);
  return [for (final v in e) v / s];
}

/// ---- Mfumo wa 1: Multinomial Naive Bayes (ML ya kawaida, inajifunza papo hapo) ----
class NaiveBayes {
  final int dim;
  final int k;
  late List<List<double>> _logLik;
  late List<double> _logPrior;
  NaiveBayes(this.dim, this.k) {
    _logLik = List.generate(k, (_) => List.filled(dim, math.log(1 / dim)));
    _logPrior = List.filled(k, math.log(1 / k));
  }

  void train(List<Sample> data, Map<String, int> idx) {
    const alpha = 0.3;
    final counts = List.generate(k, (_) => Float64List(dim));
    final totals = List.filled(k, 0.0);
    final priors = List.filled(k, 0.0);
    for (final s in data) {
      final c = idx[s.intent]!;
      priors[c] += s.weight;
      for (final f in s.x) {
        counts[c][f] += s.weight;
      }
      totals[c] += s.weight * s.x.length;
    }
    final n = priors.fold<double>(0, (a, b) => a + b);
    for (var c = 0; c < k; c++) {
      _logPrior[c] = math.log((priors[c] + 1) / (n + k));
      final den = totals[c] + alpha * dim;
      for (var f = 0; f < dim; f++) {
        _logLik[c][f] = math.log((counts[c][f] + alpha) / den);
      }
    }
  }

  List<double> predict(List<int> x) {
    final z = List<double>.filled(k, 0);
    final norm = x.isEmpty ? 1.0 : x.length.toDouble();
    for (var c = 0; c < k; c++) {
      var s = 0.0;
      for (final f in x) {
        s += _logLik[c][f];
      }
      // Joto (temperature): inapunguza kujiamini kupita kiasi kwa maswali marefu.
      z[c] = _logPrior[c] + 5.0 * s / norm;
    }
    return _softmax(z);
  }
}

/// ---- Mfumo wa 2: Deep Neural Network (MLP) ----
/// Ingizo (hashed sparse) -> Tabaka fiche 1 -> Tabaka fiche 2 -> Softmax.
/// Inafunzwa kwenye kifaa kwa backpropagation + SGD, bila maktaba yoyote.
class Mlp {
  final int dim, h1, h2, k;
  final math.Random _rnd;
  late List<Float64List> _w1; // dim x h1
  late Float64List _b1;
  late List<Float64List> _w2; // h1 x h2
  late Float64List _b2;
  late List<Float64List> _w3; // h2 x k
  late Float64List _b3;

  Mlp(this.dim, this.k, {this.h1 = 24, this.h2 = 16, int seed = 42})
      : _rnd = math.Random(seed) {
    double r(double a) => (_rnd.nextDouble() * 2 - 1) * a;
    _w1 = List.generate(dim, (_) => Float64List.fromList(List.generate(h1, (_) => r(0.25))));
    _b1 = Float64List(h1);
    _w2 = List.generate(h1, (_) => Float64List.fromList(List.generate(h2, (_) => r(math.sqrt(6 / (h1 + h2))))));
    _b2 = Float64List(h2);
    _w3 = List.generate(h2, (_) => Float64List.fromList(List.generate(k, (_) => r(math.sqrt(6 / (h2 + k))))));
    _b3 = Float64List(k);
  }

  static double _act(double v) => v > 0 ? v : 0.05 * v; // Leaky ReLU
  static double _dact(double a) => a > 0 ? 1.0 : 0.05;

  // Inarudisha (a1, a2, probs)
  (Float64List, Float64List, List<double>) _forward(List<int> x) {
    final a1 = Float64List(h1);
    for (var j = 0; j < h1; j++) {
      a1[j] = _b1[j];
    }
    for (final i in x) {
      final row = _w1[i];
      for (var j = 0; j < h1; j++) {
        a1[j] += row[j];
      }
    }
    for (var j = 0; j < h1; j++) {
      a1[j] = _act(a1[j]);
    }
    final a2 = Float64List(h2);
    for (var m = 0; m < h2; m++) {
      var s = _b2[m];
      for (var j = 0; j < h1; j++) {
        s += a1[j] * _w2[j][m];
      }
      a2[m] = _act(s);
    }
    final z = List<double>.filled(k, 0);
    for (var c = 0; c < k; c++) {
      var s = _b3[c];
      for (var m = 0; m < h2; m++) {
        s += a2[m] * _w3[m][c];
      }
      z[c] = s;
    }
    return (a1, a2, _softmax(z));
  }

  List<double> predict(List<int> x) => _forward(x).$3;

  void _step(List<int> x, int y, double weight, double lr) {
    final (a1, a2, p) = _forward(x);
    final dz = List<double>.from(p);
    dz[y] -= 1.0;
    for (var c = 0; c < k; c++) {
      dz[c] *= weight;
    }
    // da2
    final da2 = Float64List(h2);
    for (var m = 0; m < h2; m++) {
      var s = 0.0;
      for (var c = 0; c < k; c++) {
        s += _w3[m][c] * dz[c];
      }
      da2[m] = s * _dact(a2[m]);
    }
    // da1
    final da1 = Float64List(h1);
    for (var j = 0; j < h1; j++) {
      var s = 0.0;
      for (var m = 0; m < h2; m++) {
        s += _w2[j][m] * da2[m];
      }
      da1[j] = s * _dact(a1[j]);
    }
    // sasisha uzito
    for (var m = 0; m < h2; m++) {
      for (var c = 0; c < k; c++) {
        _w3[m][c] -= lr * a2[m] * dz[c];
      }
    }
    for (var c = 0; c < k; c++) {
      _b3[c] -= lr * dz[c];
    }
    for (var j = 0; j < h1; j++) {
      final row = _w2[j];
      for (var m = 0; m < h2; m++) {
        row[m] -= lr * a1[j] * da2[m];
      }
    }
    for (var m = 0; m < h2; m++) {
      _b2[m] -= lr * da2[m];
    }
    for (final i in x) {
      final row = _w1[i];
      for (var j = 0; j < h1; j++) {
        row[j] -= lr * da1[j];
      }
    }
    for (var j = 0; j < h1; j++) {
      _b1[j] -= lr * da1[j];
    }
  }

  /// Mafunzo kwa vipindi (epochs). `await` ndogo kila vipindi vichache ili
  /// skrini isigande wakati wa mafunzo.
  Future<void> train(List<Sample> data, Map<String, int> idx,
      {int epochs = 60, double lr = 0.06}) async {
    final order = List<int>.generate(data.length, (i) => i);
    for (var e = 0; e < epochs; e++) {
      order.shuffle(_rnd);
      final rate = lr * (1 - 0.7 * e / epochs);
      for (final i in order) {
        final s = data[i];
        _step(s.x, idx[s.intent]!, s.weight.clamp(0.5, 4.0), rate);
      }
      if (e % 5 == 4) await Future<void>.delayed(Duration.zero);
    }
  }
}

class IntentScore {
  final String id;
  final double p;
  const IntentScore(this.id, this.p);
}

/// Mchanganyiko (ensemble): Naive Bayes + Deep Neural Network.
class IntentModel {
  static const dim = 1024;
  final List<String> ids = kIntentExamples.keys.toList();
  late final Map<String, int> _idx = {
    for (var i = 0; i < ids.length; i++) ids[i]: i
  };
  final List<Sample> _data = [];
  late final NaiveBayes _nb = NaiveBayes(dim, ids.length);
  late final Mlp _nn = Mlp(dim, ids.length);
  bool nnReady = false;
  int get sampleCount => _data.length;

  Future<void> init(List<(String, String)> learned) async {
    kIntentExamples.forEach((id, list) {
      for (final q in list) {
        _data.add(Sample(q, id, 1.0, dim));
      }
    });
    for (final (q, id) in learned) {
      if (_idx.containsKey(id)) _data.add(Sample(q, id, 3.0, dim));
    }
    _nb.train(_data, _idx); // papo hapo
    await _nn.train(_data, _idx, epochs: 60);
    nnReady = true;
  }

  /// Alama za kila nia, kubwa kwanza.
  List<IntentScore> predict(String text) {
    final x = featurize(text, dim);
    final pn = _nb.predict(x);
    List<double> p = pn;
    if (nnReady) {
      final pd = _nn.predict(x);
      p = [for (var i = 0; i < ids.length; i++) 0.4 * pn[i] + 0.6 * pd[i]];
    }
    final out = [for (var i = 0; i < ids.length; i++) IntentScore(ids[i], p[i])];
    out.sort((a, b) => b.p.compareTo(a.p));
    return out;
  }

  /// Kujifunza kutokana na maoni ya mtumiaji (online learning).
  Future<void> learn(String text, String intent) async {
    if (!_idx.containsKey(intent)) return;
    _data.add(Sample(text, intent, 3.0, dim));
    _nb.train(_data, _idx);
    await _nn.train(_data, _idx, epochs: 15, lr: 0.03);
  }
}
