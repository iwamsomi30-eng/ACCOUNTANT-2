/// Zana za maandishi za ELAPS AI (hazihitaji intaneti wala kifurushi chochote).

/// Herufi ndogo, bila alama; nafasi moja kati ya maneno.
String normalizeText(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

List<String> splitWords(String normalized) =>
    normalized.isEmpty ? <String>[] : normalized.split(' ');

/// Umbali wa Levenshtein (idadi ndogo ya mabadiliko ya herufi).
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  var cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = prev[j] + 1;
      if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
      if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
      cur[j] = v;
    }
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[b.length];
}

/// Maneno yanalingana hata kukiwa na kosa dogo la uandishi
/// (mf. "benedikt" ~ "benedict"). Maneno mafupi yanahitaji ulinganifu kamili.
bool fuzzyEq(String a, String b) {
  if (a == b) return true;
  final m = a.length < b.length ? a.length : b.length;
  if (m < 5) return false;
  final maxD = m >= 8 ? 2 : 1;
  if ((a.length - b.length).abs() > maxD) return false;
  return levenshtein(a, b) <= maxD;
}

int _hash(String s) {
  var h = 7;
  for (final u in s.codeUnits) {
    h = (h * 31 + u) & 0x7fffffff;
  }
  return (h ^ (h >> 15)) & 0x7fffffff;
}

/// Vipengele (features) vya maandishi: maneno, jozi za maneno na vipande vya
/// herufi 3 (char trigrams) -- hivyo makosa madogo ya uandishi hayaharibu uelewa.
/// Matokeo: nafasi (indices) za kipekee ndani ya [dim].
List<int> featurize(String text, int dim) {
  final words = splitWords(normalizeText(text));
  final set = <int>{};
  void add(String f) => set.add(_hash(f) % dim);
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    add('w:$w');
    if (i + 1 < words.length) add('b:$w _${words[i + 1]}');
    final p = '^$w\$';
    if (p.length >= 4) {
      for (var k = 0; k + 3 <= p.length; k++) {
        add('c:${p.substring(k, k + 3)}');
      }
    }
  }
  final out = set.toList()..sort();
  return out;
}

const Map<String, int> _numWords = {
  'moja': 1, 'mbili': 2, 'tatu': 3, 'nne': 4, 'tano': 5,
  'sita': 6, 'saba': 7, 'nane': 8, 'tisa': 9, 'kumi': 10,
};

/// "tano bora", "top 3", "5 bora" -> namba; vinginevyo null.
int? parseTopN(String normalized) {
  final w = splitWords(normalized);
  for (var i = 0; i < w.length; i++) {
    final x = w[i];
    int? n = int.tryParse(x) ?? _numWords[x];
    if (n == null) continue;
    final next = i + 1 < w.length ? w[i + 1] : '';
    final prev = i > 0 ? w[i - 1] : '';
    if (next == 'bora' || prev == 'top' || prev == 'bora' || next == 'wa') {
      if (n >= 1 && n <= 30) return n;
    }
  }
  return null;
}

/// Inatafuta kiasi cha pesa kwenye swali: "50000", "50,000", "50k", "elfu 50",
/// "laki 2", "milioni 1". Inarudisha null kama hakuna.
int? parseAmount(String raw) {
  var s = raw.toLowerCase();
  // 1,000,000 -> 1000000
  var prev = '';
  while (prev != s) {
    prev = s;
    s = s.replaceAllMapped(
        RegExp(r'(\d)[,.](\d{3})(?!\d)'), (m) => '${m[1]}${m[2]}');
  }
  final mult = {'elfu': 1000, 'laki': 100000, 'milioni': 1000000};
  final a = RegExp(r'\b(elfu|laki|milioni)\s*(\d+)').firstMatch(s);
  if (a != null) return int.parse(a[2]!) * mult[a[1]]!;
  final b = RegExp(r'(\d+)\s*(k|elfu|laki|milioni|m)\b').firstMatch(s);
  if (b != null) {
    final u = b[2]!;
    final f = u == 'k' ? 1000 : (u == 'm' ? 1000000 : mult[u]!);
    return int.parse(b[1]!) * f;
  }
  final c = RegExp(r'\b(\d{3,})\b').firstMatch(s);
  if (c != null) return int.parse(c[1]!);
  return null;
}
