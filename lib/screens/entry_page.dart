import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/record_view.dart';
import '../l10n.dart';

class EntryPage extends StatefulWidget {
  final AppState app;
  const EntryPage({super.key, required this.app});
  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  static const _roman = ['i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x'];
  final Map<String, TextEditingController> _c = {};
  int _sel = 0;

  String _kk(String kanda) => 'K|$kanda';

  @override
  void initState() {
    super.initState();
    for (final k in kSeedKanda) {
      _c[_kk(k.name)] = TextEditingController();
      for (final j in k.jumuiya) {
        _c[AppState.jKey(k.name, j)] = TextEditingController();
      }
    }
  }

  int _val(String key) => int.tryParse(_c[key]?.text ?? '') ?? 0;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Sehemu ya kuandika: huwa tupu kila wakati (ada zilizohifadhiwa hazionekani hapa).
  Widget _field(String key, {bool big = false}) => TextField(
        controller: _c[key],
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        style: TextStyle(fontSize: big ? 16 : 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: tr('weka data', 'insert data'),
          hintStyle: TextStyle(color: C.muted.withOpacity(.8), fontSize: big ? 14 : 12),
          contentPadding: EdgeInsets.symmetric(horizontal: big ? 14 : 8, vertical: big ? 15 : 9),
        ),
      );

  /// Simu: kadi moja kwa kila Kanda/Jumuiya (jina juu, sehemu ya kuandika chini, upana kamili).
  Widget _entryCard(String no, String name, bool saved, String key) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: cardBox(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(8)),
              child: t(no, size: 12.5, color: C.muted),
            ),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: t(name, bold: true, size: 15),
            )),
            if (saved)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Icon(Icons.check_circle, size: 20, color: C.green),
              ),
          ]),
          const SizedBox(height: 12),
          _field(key, big: true),
        ]),
      );

  /// Jina lenye alama ya ✓ ikiwa ada tayari imehifadhiwa.
  Widget _nameCell(String name, bool saved) => Row(children: [
        Expanded(child: t(name)),
        if (saved) const Icon(Icons.check_circle, size: 16, color: C.green),
      ]);

  void _clear() {
    for (final c in _c.values) {
      c.clear();
    }
    setState(() {});
  }

  /// Ada za Kanda na za Jumuiya zinahifadhiwa pamoja; kisha fomu inakuwa tupu.
  Future<void> _save() async {
    final k = <String, int>{};
    final j = <String, int>{};
    for (final kd in kSeedKanda) {
      final kv = _val(_kk(kd.name));
      if (kv > 0) k[kd.name] = kv;
      for (final jm in kd.jumuiya) {
        final key = AppState.jKey(kd.name, jm);
        final v = _val(key);
        if (v > 0) j[key] = v;
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    if (k.isEmpty && j.isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(tr('Hakuna ada iliyojazwa. Jaza angalau sehemu moja kisha bonyeza Hifadhi.', 'No fee has been entered. Fill at least one field and press Save.'))));
      return;
    }
    final n = await widget.app.saveEntries(k, j);
    if (!mounted) return;
    _clear();
    messenger.showSnackBar(SnackBar(
      backgroundColor: C.btnGreen,
      content: Text(
          tr('Ada za Kanda ${k.length} na Jumuiya ${j.length} zimehifadhiwa pamoja. Rekodi mpya: $n.', 'Zone fees ${k.length} and community fees ${j.length} were saved together. New records: $n.')),
    ));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, cons) => _body(context, cons.maxWidth < kNarrow));

  Widget _body(BuildContext context, bool narrow) {
    final app = widget.app;
    final kd = kSeedKanda[_sel];
    var jTotal = 0;
    var typedJ = 0;
    for (final j in kd.jumuiya) {
      final v = _val(AppState.jKey(kd.name, j));
      jTotal += v;
      if (v > 0) typedJ++;
    }
    final typedK = _val(_kk(kd.name));
    final recent = app.receipts.reversed.take(6).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 14, narrow ? 18 : 14, narrow ? 16 : 14, narrow ? 100 : 14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tl(context, 'Uingizaji wa Data', 'Data Entry', bold: true, size: narrow ? 22 : 18),
            tl(context, 'Michango ${DateTime.now().year}', 'Contributions ${DateTime.now().year}', color: C.muted, size: 12),
          ],
        ),
        const SizedBox(height: 12),
        sectionTitle(tr('Kanda ya Kanisa', 'Local Church Zone')),
        if (narrow) ...[
          for (var i = 0; i < kSeedKanda.length; i++)
            _entryCard('${i + 1}', kSeedKanda[i].name, (app.kandaFee[kSeedKanda[i].name] ?? 0) > 0, _kk(kSeedKanda[i].name)),
        ] else ...[
          gridRow([
            cell(t('Na.', color: C.muted, size: 11), w: 52),
            cell(tl(context, 'Jina la Kanda', 'Zone Name', color: C.muted, size: 11)),
            cell(tl(context, 'Ada ya Kanda', 'Zone Fee', color: C.muted, size: 11, align: TextAlign.right), w: 170),
          ], header: true),
          for (var i = 0; i < kSeedKanda.length; i++)
            gridRow([
              cell(t('${i + 1}'), w: 52),
              cell(_nameCell(kSeedKanda[i].name, (app.kandaFee[kSeedKanda[i].name] ?? 0) > 0)),
              cell(_field(_kk(kSeedKanda[i].name)), w: 170),
            ]),
        ],
        const SizedBox(height: 16),
        sectionTitle(tr('Jumuiya Ndogo za Kikristo · Kanda ${_sel + 1}', 'Small Christian Communities · Zone ${_sel + 1}')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < kSeedKanda.length; i++)
            ChoiceChip(
              label: Text(tr('Kanda ${i + 1}', 'Zone ${i + 1}')),
              selected: _sel == i,
              selectedColor: C.rose,
              checkmarkColor: Colors.white,
              visualDensity: narrow ? VisualDensity.standard : VisualDensity.compact,
              labelStyle: TextStyle(color: _sel == i ? Colors.white : C.text, fontSize: narrow ? 14 : 12.5),
              onSelected: (_) => setState(() => _sel = i),
            ),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: C.soft,
            border: Border.all(color: C.border, width: .8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(spacing: 18, runSpacing: 4, children: [
            t(kd.name, bold: true, color: C.navy),
            tl(context, 'Ada ya Kanda unayoingiza: ${typedK > 0 ? 'TSh ${fmt(typedK)}' : '-'}', 'Zone fee entered: ${typedK > 0 ? 'TSh ${fmt(typedK)}' : '-'}', size: 12),
            tl(context, 'Jumuiya unazoingiza: $typedJ / ${kd.jumuiya.length}', 'Communities entered: $typedJ / ${kd.jumuiya.length}', size: 12),
          ]),
        ),
        const SizedBox(height: 8),
        if (narrow) ...[
          for (var i = 0; i < kd.jumuiya.length; i++)
            _entryCard(_roman[i], kd.jumuiya[i],
                (app.jumuiyaFee[AppState.jKey(kd.name, kd.jumuiya[i])] ?? 0) > 0,
                AppState.jKey(kd.name, kd.jumuiya[i])),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.cardAlt,
              border: Border.all(color: C.border, width: .8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Expanded(child: tl(context, 'Jumla ya unazoingiza (Kanda hii)', 'Total entered (this zone)', bold: true, size: 13.5)),
              t(jTotal > 0 ? fmt(jTotal) : '-', bold: true, size: 16),
            ]),
          ),
        ] else ...[
          gridRow([
            cell(t('No.', color: C.muted, size: 11), w: 52),
            cell(tl(context, 'Jumuiya zake', 'Communities', color: C.muted, size: 11)),
            cell(tl(context, 'Ada ya Jumuiya', 'Community Fee', color: C.muted, size: 11, align: TextAlign.right), w: 170),
          ], header: true),
          for (var i = 0; i < kd.jumuiya.length; i++)
            gridRow([
              cell(t(_roman[i]), w: 52),
              cell(_nameCell(kd.jumuiya[i],
                  (app.jumuiyaFee[AppState.jKey(kd.name, kd.jumuiya[i])] ?? 0) > 0)),
              cell(_field(AppState.jKey(kd.name, kd.jumuiya[i])), w: 170),
            ]),
          gridRow([
            cell(const SizedBox(), w: 52),
            cell(tl(context, 'Jumla ya unazoingiza (Kanda hii)', 'Total entered (this zone)', bold: true)),
            cell(t(jTotal > 0 ? fmt(jTotal) : '-', bold: true, align: TextAlign.right), w: 170),
          ], total: true),
        ],
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(
                backgroundColor: C.btnGreen,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: narrow ? 14 : 10)),
            icon: const Icon(Icons.save, size: 18),
            label: Text(tr('Hifadhi', 'Save')),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: narrow ? 14 : 10)),
            onPressed: _clear,
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: Text(tr('Futa fomu', 'Clear form')),
          ),
        ]),
        const SizedBox(height: 6),
        tl(context, 'Alama ya ✓ inamaanisha ada tayari imehifadhiwa (iangalie kwenye Daftari au Jumuiya). Kila Hifadhi inaongeza taarifa MPYA yenye namba na tarehe yake. Za zamani hazibadilishwi.', 'A ✓ means the fee is already saved (check the Ledger or Communities). Each Save adds a NEW record with its own number and date. Older records are not changed.',
            color: C.muted, size: 11),
        const SizedBox(height: 18),
        sectionTitle(tr('Muhtasari wa Risiti', 'Receipt Previews')),
        if (recent.isEmpty)
          tl(context, 'Bado hakuna rekodi. Weka ada kisha bonyeza Hifadhi.', 'No records yet. Enter a fee and press Save.', color: C.muted, size: 12)
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in recent)
              InkWell(
                onTap: () => showRecordView(context, app, r),
                child: Container(
                  width: narrow ? double.infinity : 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.card,
                    border: Border.all(color: C.border, width: .8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      tl(context, 'Risiti Na. ${r.noText}', 'Receipt No. ${r.noText}', color: C.muted, size: 11),
                      const Icon(Icons.receipt_long, size: 16, color: C.muted),
                    ]),
                    const SizedBox(height: 4),
                    t(r.isKanda ? tr('Ada ya Kanda', 'Zone Fee') : r.jumuiya, bold: true),
                    t(r.kanda, color: C.muted, size: 11),
                    tl(context, 'Ada ya Kanda: ${(app.kandaFee[r.kanda] ?? 0) > 0 ? 'TSh ${fmt(app.kandaFee[r.kanda]!)}' : 'haijajazwa'}', 'Zone fee: ${(app.kandaFee[r.kanda] ?? 0) > 0 ? 'TSh ${fmt(app.kandaFee[r.kanda]!)}' : 'not entered'}',
                        color: C.muted, size: 11),
                    const SizedBox(height: 6),
                    t('TSh ${fmt(r.amount)}', bold: true, size: 15, color: C.navy),
                  ]),
                ),
              ),
          ]),
      ],
    );
  }
}
