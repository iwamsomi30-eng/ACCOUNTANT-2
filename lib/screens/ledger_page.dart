import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/export_ui.dart';
import '../widgets/record_view.dart';
import '../l10n.dart';

class LedgerPage extends StatefulWidget {
  final AppState app;
  const LedgerPage({super.key, required this.app});
  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  String _q = '';

  Future<void> _edit(Receipt r) async {
    final c = TextEditingController(text: r.amount.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Hariri Rekodi ${r.noText}', 'Edit Record ${r.noText}')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          t(r.isKanda ? tr('Ada ya ${r.kanda}', 'Fee for ${r.kanda}') : r.jumuiya, bold: true),
          const SizedBox(height: 10),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText: tr('Kiasi cha Ada (TSh)', 'Fee Amount (TSh)')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Ghairi', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Hifadhi', 'Save'))),
        ],
      ),
    );
    final v = int.tryParse(c.text);
    if (ok == true && v != null && v > 0) {
      await widget.app.updateReceiptAmount(r, v);
    }
  }

  /// Simu: kila rekodi ni kadi yenye nafasi (badala ya jedwali la upana 1080).
  Widget _card(Receipt r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        decoration: cardBox(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: t(r.noText, size: 12, color: C.muted)),
            t(dateText(r.date), size: 12, color: C.muted),
            const SizedBox(width: 6),
          ]),
          const SizedBox(height: 8),
          r.isKanda
              ? tl(context, 'Ada ya Kanda', 'Zone Fee', bold: true, size: 15, color: C.navy)
              : t(r.jumuiya, bold: true, size: 15),
          const SizedBox(height: 2),
          t(r.kanda, size: 12.5, color: C.muted),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: t('TSh ${fmt(r.amount)}', bold: true, size: 17, color: C.navy)),
            TextButton.icon(
              onPressed: () => showRecordView(context, widget.app, r),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(tr('Angalia', 'View')),
            ),
            TextButton(
                onPressed: () => _edit(r),
                child: Text(tr('Hariri', 'Edit'), style: const TextStyle(color: C.danger))),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final all = widget.app.receipts.reversed.toList();
    final q = _q.toLowerCase();
    final list = all
        .where((r) =>
            q.isEmpty ||
            r.jumuiya.toLowerCase().contains(q) ||
            r.kanda.toLowerCase().contains(q) ||
            r.aina.toLowerCase().contains(q) ||
            r.noText.contains(q))
        .toList();

    return LayoutBuilder(builder: (context, cons) {
    final narrow = cons.maxWidth < kNarrow;
    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 14, narrow ? 18 : 14, narrow ? 16 : 14, narrow ? 0 : 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tl(context, 'Daftari la Rekodi', 'Records Ledger', bold: true, size: narrow ? 22 : 18),
            tl(context, 'Rekodi ${all.length}', '${all.length} Records', color: C.muted, size: 12),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: narrow ? double.infinity : 320,
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: tr('Tafuta jumuiya, kanda au namba', 'Search community, zone or number'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: C.border)),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: list.isEmpty
                ? null
                : () => runExport(context, 'Ledger_${ExportService.stamp()}', 'pdf',
                    () => ExportService.ledgerPdf(widget.app, list)),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: Text(tr('Export PDF', 'Export PDF')),
          ),
          OutlinedButton.icon(
            onPressed: list.isEmpty
                ? null
                : () => runExport(context, 'Ledger_${ExportService.stamp()}', 'xlsx',
                    () async => ExportService.ledgerExcel(widget.app, list)),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: Text(tr('Export Excel', 'Export Excel')),
          ),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? Center(child: tl(context, 'Hakuna rekodi zilizopatikana.', 'No records found.', color: C.muted))
              : narrow
              ? ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(list[i]),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1080,
                    child: Column(children: [
                      gridRow([
                        cell(tl(context, 'Risiti Na.', 'Receipt No.', color: C.muted, size: 11), w: 190),
                        cell(tl(context, 'Jina la Kanda', 'Zone Name', color: C.muted, size: 11), w: 210),
                        cell(tl(context, 'Jina la Jumuiya', 'Community Name', color: C.muted, size: 11), w: 220),
                        cell(tl(context, 'Ada (TZS)', 'Fee (TZS)', color: C.muted, size: 11, align: TextAlign.right), w: 130),
                        cell(tl(context, 'Tarehe', 'Date', color: C.muted, size: 11), w: 130),
                        cell(tl(context, 'Kitendo', 'Action', color: C.muted, size: 11), w: 200),
                      ], header: true),
                      Expanded(
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final r = list[i];
                            return gridRow([
                              cell(t(r.noText, size: 12), w: 190),
                              cell(t(r.kanda, size: 12), w: 210),
                              cell(
                                r.isKanda
                                    ? tl(context, 'Ada ya Kanda', 'Zone Fee', size: 12, color: C.navy)
                                    : t(r.jumuiya, size: 12),
                                w: 220,
                              ),
                              cell(t(fmt(r.amount), size: 12, align: TextAlign.right), w: 130),
                              cell(t(dateText(r.date), size: 12), w: 130),
                              cell(
                                Row(children: [
                                  TextButton.icon(
                                    onPressed: () => showRecordView(context, widget.app, r),
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: Text(tr('Angalia', 'View')),
                                  ),
                                  TextButton(
                                      onPressed: () => _edit(r),
                                      child: Text(tr('Hariri', 'Edit'), style: const TextStyle(color: C.danger))),
                                ]),
                                w: 200,
                              ),
                            ]);
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
        ),
      ]),
    );
    });
  }
}
