import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../data/members_seed.dart';
import '../util.dart';
import '../l10n.dart';

/// Rekodi kwenye Ledger. type: 'J' = ada ya Jumuiya, 'K' = ada ya Kanda.
class Receipt {
  int no;
  String type;
  String kanda;
  String jumuiya;
  int amount;
  DateTime date;
  Receipt({
    required this.no,
    this.type = 'J',
    required this.kanda,
    required this.jumuiya,
    required this.amount,
    required this.date,
  });

  bool get isKanda => type == 'K';
  /// Namba ya kipekee ya mfululizo (haijirudii kamwe).
  String get seq => no.toString().padLeft(4, '0');

  /// Namba ya risiti: MWAKA-TAREHE(MMDD)-NAMBA YA KIPEKEE (tarakimu 4)
  /// Mfano: 2026-1012-0007
  String get noText {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}${two(date.day)}-$seq';
  }
  String get aina => isKanda ? 'Kanda' : 'Jumuiya';

  Map<String, dynamic> toJson() => {
        'no': no,
        'type': type,
        'kanda': kanda,
        'jumuiya': jumuiya,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        no: j['no'] as int,
        type: (j['type'] as String?) ?? 'J',
        kanda: j['kanda'] as String,
        jumuiya: j['jumuiya'] as String,
        amount: j['amount'] as int,
        date: DateTime.parse(j['date'] as String),
      );
}

/// Mtoa mchango wa Jumuiya (jina + namba ya simu).
class Member {
  String name;
  String phone;
  Member(this.name, [this.phone = '']);
  Map<String, dynamic> toJson() => {'n': name, 'p': phone};
  factory Member.fromJson(Map<String, dynamic> j) =>
      Member(j['n'] as String, (j['p'] as String?) ?? '');
}

class JRow {
  final String name;
  final int amount;
  final int count; // idadi ya taarifa zilizoingizwa kwa Jumuiya hii
  const JRow(this.name, this.amount, this.count);
}

/// Taarifa kamili za rekodi moja pamoja na za Kanda yake.
class RecordInfo {
  final Receipt r;
  final Kanda kanda;
  final int kandaFee;
  final List<JRow> rows;
  const RecordInfo(this.r, this.kanda, this.kandaFee, this.rows);

  int get jumuiyaTotal => rows.fold(0, (s, e) => s + e.amount);
  int get paid => rows.where((e) => e.amount > 0).length;
  int get total => kandaFee + jumuiyaTotal;
}

class Tip {
  final String kind; // warn, info, ok, idea
  final String text;
  const Tip(this.kind, this.text);
}

class AppState extends ChangeNotifier {
  final Map<String, int> kandaFee = {};
  final Map<String, int> jumuiyaFee = {};
  final List<Receipt> receipts = [];
  int nextNo = 1;
  /// Majina ya watoa michango kwa kila Jumuiya (ufunguo: 'Kanda|Jumuiya').
  final Map<String, List<Member>> members = {};

  static String jKey(String k, String j) => '$k|$j';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _loadMembers(p);
    final raw = p.getString('data_v1');
    if (raw == null) return;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    receipts
      ..clear()
      ..addAll((m['receipts'] as List)
          .map((e) => Receipt.fromJson(e as Map<String, dynamic>)));
    nextNo = m['nextNo'] as int;
    _migrateNames();
    _recompute();

    // Uhamisho: ada za zamani zisizo na rekodi zinakuwa rekodi (tarehe ya leo).
    var migrated = false;
    void legacy(Map? old, String type, bool isK) {
      if (old == null) return;
      old.forEach((key, v) {
        final k = key.toString();
        final saved = v as int;
        final have = isK ? (kandaFee[k] ?? 0) : (jumuiyaFee[k] ?? 0);
        if (saved > have) {
          final parts = isK ? [k, ''] : k.split('|');
          receipts.add(Receipt(
            no: nextNo++,
            type: type,
            kanda: parts[0],
            jumuiya: parts[1],
            amount: saved - have,
            date: DateTime.now(),
          ));
          migrated = true;
        }
      });
    }

    legacy(m['kandaFee'] as Map?, 'K', true);
    legacy(m['jumuiyaFee'] as Map?, 'J', false);
    if (migrated) {
      _recompute();
      await _persist();
    }
  }

  void _loadMembers(SharedPreferences p) {
    members.clear();
    final raw = p.getString('members_v1');
    if (raw != null) {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      m.forEach((k, v) => members[k] = (v as List)
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList());
      return;
    }
    // Mara ya kwanza: pakia majina kutoka Excel (jumuiya zisizo na majina zinabaki wazi).
    for (var i = 0; i < kSeedKanda.length && i < kSeedMembers.length; i++) {
      final k = kSeedKanda[i];
      for (var j = 0; j < k.jumuiya.length && j < kSeedMembers[i].length; j++) {
        members[jKey(k.name, k.jumuiya[j])] = [
          for (final (n, ph) in kSeedMembers[i][j]) Member(n, ph),
        ];
      }
    }
  }

  Future<void> _persistMembers() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('members_v1',
        jsonEncode(members.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
  }

  List<Member> membersFor(String kanda, String jumuiya) =>
      members.putIfAbsent(jKey(kanda, jumuiya), () => []);

  int get memberCount => members.values.fold(0, (s, l) => s + l.length);

  Future<void> addMember(String kanda, String jumuiya, String name, String phone) async {
    membersFor(kanda, jumuiya).add(Member(name.trim(), phone.trim()));
    await _persistMembers();
    notifyListeners();
  }

  Future<void> editMember(Member m, String name, String phone) async {
    m.name = name.trim();
    m.phone = phone.trim();
    await _persistMembers();
    notifyListeners();
  }

  Future<void> removeMember(String kanda, String jumuiya, Member m) async {
    membersFor(kanda, jumuiya).remove(m);
    await _persistMembers();
    notifyListeners();
  }

  /// Hubadilisha majina ya zamani ya Kanda/Jumuiya kuwa mapya (Kanda 15) ili rekodi zisipotee.
  void _migrateNames() {
    bool exists(String k, String? j) => kSeedKanda.any(
        (x) => x.name == k && (j == null || x.jumuiya.contains(j)));
    for (final r in receipts) {
      final k = kLegacyKanda[r.kanda] ?? r.kanda;
      if (r.isKanda) {
        if (exists(k, null)) r.kanda = k;
      } else {
        final j = kLegacyJumuiya[r.jumuiya] ?? r.jumuiya;
        if (exists(k, j)) {
          r.kanda = k;
          r.jumuiya = j;
        }
      }
    }
  }

  /// Jumla za Kanda na Jumuiya hutokana na rekodi zote (kila taarifa ni rekodi yake).
  void _recompute() {
    kandaFee.clear();
    jumuiyaFee.clear();
    for (final r in receipts) {
      if (r.isKanda) {
        kandaFee[r.kanda] = (kandaFee[r.kanda] ?? 0) + r.amount;
      } else {
        final key = jKey(r.kanda, r.jumuiya);
        jumuiyaFee[key] = (jumuiyaFee[key] ?? 0) + r.amount;
      }
    }
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      'data_v1',
      jsonEncode({
        'kandaFee': kandaFee,
        'jumuiyaFee': jumuiyaFee,
        'receipts': receipts.map((r) => r.toJson()).toList(),
        'nextNo': nextNo,
      }),
    );
  }

  // ---- Jumla ----
  int get totalKanda => kandaFee.values.fold(0, (a, b) => a + b);
  int get totalJumuiya => jumuiyaFee.values.fold(0, (a, b) => a + b);
  int get total => totalKanda + totalJumuiya;
  int get jumuiyaCount => kSeedKanda.fold(0, (s, k) => s + k.jumuiya.length);
  int get paidJumuiya => jumuiyaFee.values.where((v) => v > 0).length;

  Kanda kandaByName(String n) => kSeedKanda.firstWhere((k) => k.name == n,
      orElse: () => Kanda(n, const []));

  int kandaTotal(Kanda k) {
    var s = kandaFee[k.name] ?? 0;
    for (final j in k.jumuiya) {
      s += jumuiyaFee[jKey(k.name, j)] ?? 0;
    }
    return s;
  }

  List<String> unpaidJumuiya() {
    final out = <String>[];
    for (final k in kSeedKanda) {
      for (final j in k.jumuiya) {
        if ((jumuiyaFee[jKey(k.name, j)] ?? 0) <= 0) out.add(j);
      }
    }
    return out;
  }

  Kanda? topKanda() {
    Kanda? best;
    var bestV = 0;
    for (final k in kSeedKanda) {
      final v = kandaTotal(k);
      if (v > bestV) {
        bestV = v;
        best = k;
      }
    }
    return best;
  }

  /// Taarifa zote zilizoingizwa kwa Jumuiya moja (au Kanda ikiwa j == null), mpya kwanza.
  List<Receipt> entriesFor(String kanda, String? j) {
    final list = receipts
        .where((r) => j == null
            ? (r.isKanda && r.kanda == kanda)
            : (!r.isKanda && r.kanda == kanda && r.jumuiya == j))
        .toList();
    list.sort((a, b) => b.no.compareTo(a.no));
    return list;
  }

  List<JRow> _rows(Kanda k) => [
        for (final j in k.jumuiya)
          JRow(j, jumuiyaFee[jKey(k.name, j)] ?? 0, entriesFor(k.name, j).length),
      ];

  RecordInfo infoFor(Receipt r) {
    final k = kandaByName(r.kanda);
    return RecordInfo(r, k, kandaFee[k.name] ?? 0, _rows(k));
  }

  /// Taarifa za Kanda pekee (rekodi ya mfano haitumiki popote).
  RecordInfo infoForKanda(Kanda k) => RecordInfo(
      Receipt(no: 0, type: 'K', kanda: k.name, jumuiya: '', amount: 0, date: DateTime.now()),
      k,
      kandaFee[k.name] ?? 0,
      _rows(k));

  // ---- Kuhifadhi ----
  /// Ada za Kanda na za Jumuiya zinahifadhiwa pamoja kwa mara moja.
  /// Kila ada iliyojazwa inakuwa taarifa MPYA yenye namba na tarehe yake (haibadilishi za zamani).
  /// Inarudisha idadi ya rekodi mpya.
  Future<int> saveEntries(Map<String, int> k, Map<String, int> j) async {
    final now = DateTime.now();
    var created = 0;
    for (final e in k.entries) {
      if (e.value <= 0) continue;
      receipts.add(Receipt(
          no: nextNo++, type: 'K', kanda: e.key, jumuiya: '', amount: e.value, date: now));
      created++;
    }
    for (final e in j.entries) {
      if (e.value <= 0) continue;
      final parts = e.key.split('|');
      receipts.add(Receipt(
          no: nextNo++, type: 'J', kanda: parts[0], jumuiya: parts[1], amount: e.value, date: now));
      created++;
    }
    _recompute();
    await _persist();
    notifyListeners();
    return created;
  }

  Future<void> updateReceiptAmount(Receipt r, int amount) async {
    r.amount = amount;
    _recompute();
    await _persist();
    notifyListeners();
  }

  // ---- ELAPS AI (sheria rahisi, offline) ----
  List<Tip> tips() {
    final out = <Tip>[];
    final unpaid = unpaidJumuiya();
    if (unpaid.isNotEmpty) {
      final shown = unpaid.take(2).join(', ');
      final moreSw = unpaid.length > 2 ? ' na ${unpaid.length - 2} nyingine' : '';
      final moreEn = unpaid.length > 2 ? ' and ${unpaid.length - 2} others' : '';
      out.add(Tip('warn', tr(
          '$shown$moreSw hazina ada. Weka kiasi au thibitisha ni sifuri.',
          '$shown$moreEn have no fee. Enter an amount or confirm it is zero.')));
    }
    final blank = kSeedKanda.where((k) => (kandaFee[k.name] ?? 0) == 0).length;
    if (blank > 0) {
      out.add(Tip('info', tr(
          'Ada ya Kanda bado haijajazwa kwa Kanda $blank kati ya ${kSeedKanda.length}.',
          'Zone fees are still missing for $blank of ${kSeedKanda.length} zones.')));
    }
    final top = topKanda();
    if (top != null) {
      out.add(Tip('ok', tr(
          '${top.name} inaongoza kwa TSh ${fmt(kandaTotal(top))}.',
          '${top.name} leads with TSh ${fmt(kandaTotal(top))}.')));
    }
    out.add(Tip('idea', tr(
        'Ushauri: hifadhi nakala ya rekodi zako kila wiki (Export).',
        'Tip: export a backup of your records every week.')));
    return out;
  }

  // Maswali ya ELAPS AI yanashughulikiwa na lib/ai/elaps_engine.dart
}
