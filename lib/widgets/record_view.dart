import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../l10n.dart';
import 'common.dart';
import 'export_ui.dart';

void showRecordView(BuildContext context, AppState app, Receipt r) {
  final i = app.infoFor(r);
  final all = app.entriesFor(r.kanda, r.isKanda ? null : r.jumuiya);

  Widget kv(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 2, child: t(a, color: C.muted, size: 12)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: t(b, bold: bold, align: TextAlign.right)),
          ],
        ),
      );

  Widget box(String title, List<Widget> kids) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: cardBox(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle(title),
          ...kids,
        ]),
      );

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Image.asset('assets/logo.png', width: 44, height: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  tl(context, 'WANAWAKE WAKATOLIKI TANZANIA', 'CATHOLIC WOMEN OF TANZANIA', bold: true, size: 12),
                  tl(context, r.isKanda ? 'Ada ya Kanda' : 'Risiti ya Jumuiya',
                      r.isKanda ? 'Zone Fee' : 'Community Receipt', color: C.navy, size: 11),
                ]),
              ),
              t('No. ${r.noText}', bold: true, size: 16, color: C.navy),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              box(tr('Taarifa za Rekodi', 'Record Details'), [
                kv(tr('Aina', 'Type'), r.isKanda ? tr('Ada ya Kanda', 'Zone Fee') : tr('Ada ya Jumuiya', 'Community Fee')),
                if (!r.isKanda) kv(tr('Jina la Jumuiya', 'Community Name'), r.jumuiya, bold: true),
                kv(tr('Ada', 'Fee'), 'TSh ${fmt(r.amount)}/=', bold: true),
                kv(tr('Tarehe', 'Date'), dateText(r.date)),
              ]),
              box(tr('Taarifa za Kanda', 'Zone Details'), [
                kv(tr('Jina la Kanda', 'Zone Name'), i.kanda.name, bold: true),
                kv(tr('Ada Kanda', 'Zone Fee'), i.kandaFee > 0 ? 'TSh ${fmt(i.kandaFee)}' : tr('Haijajazwa', 'Not entered')),
                kv(tr('Jumuiya zilizolipa', 'Communities Paid'), '${i.paid} / ${i.kanda.jumuiya.length}'),
                kv(tr('Jumla ya ada za Jumuiya', 'Total Community Fees'), 'TSh ${fmt(i.jumuiyaTotal)}'),
                kv(tr('Jumla kuu ya Kanda', 'Zone Grand Total'), 'TSh ${fmt(i.total)}', bold: true),
              ]),
              box(
                r.isKanda
                    ? tr('Taarifa zote za ada ya Kanda (${all.length})', 'All zone fee records (${all.length})')
                    : tr('Taarifa zote za Jumuiya hii (${all.length})', 'All records for this community (${all.length})'),
                [
                  for (final e in all)
                    Container(
                      color: e.no == r.no ? C.soft : null,
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                      child: Row(children: [
                        SizedBox(width: 150, child: t(e.noText, size: 11, bold: e.no == r.no)),
                        Expanded(child: t(dateText(e.date), size: 12)),
                        t(fmt(e.amount), size: 12, bold: e.no == r.no),
                      ]),
                    ),
                  if (all.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: tl(context,
                          'Jumla: TSh ${fmt(all.fold<int>(0, (s, e) => s + e.amount))}',
                          'Total: TSh ${fmt(all.fold<int>(0, (s, e) => s + e.amount))}',
                          bold: true, size: 12, align: TextAlign.right),
                    ),
                ],
              ),
              box(tr('Jumuiya za Kanda hii', 'Communities in this Zone'), [
                for (final j in i.rows)
                  Container(
                    color: (!r.isKanda && j.name == r.jumuiya) ? C.soft : null,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                    child: Row(children: [
                      Expanded(child: t(j.name, size: 12, bold: !r.isKanda && j.name == r.jumuiya)),
                      const SizedBox(width: 10),
                      t(j.count > 0 ? tr('${j.count} taarifa', '${j.count} records') : '', size: 11, color: C.muted),
                      const SizedBox(width: 12),
                      t(j.amount > 0 ? fmt(j.amount) : '-', size: 12),
                    ]),
                  ),
              ]),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
              FilledButton.icon(
                onPressed: () => runExport(ctx, 'Rekodi_${r.noText}', 'pdf', () => ExportService.recordPdf(app, r)),
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(tr('Export PDF', 'Export PDF')),
              ),
              OutlinedButton.icon(
                onPressed: () => runExport(ctx, 'Rekodi_${r.noText}', 'xlsx', () async => ExportService.recordExcel(app, r)),
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: Text(tr('Export Excel', 'Export Excel')),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Funga', 'Close'))),
            ]),
          ),
        ]),
      ),
    ),
  );
}

void showJumuiyaView(BuildContext context, AppState app, Kanda k, String j) =>
    _showEntries(context, app, k, j);

void showKandaView(BuildContext context, AppState app, Kanda k) =>
    _showEntries(context, app, k, null);

void _showEntries(BuildContext context, AppState app, Kanda k, String? j) {
  final list = app.entriesFor(k.name, j);
  if (list.isEmpty) {
    _showUnpaid(context, app, k, j);
    return;
  }
  final sum = list.fold<int>(0, (s, e) => s + e.amount);
  final kf = app.kandaFee[k.name] ?? 0;
  final title = j ?? tr('Ada ya ${k.name}', 'Fee for ${k.name}');

  Widget kv(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          t(a, color: C.muted, size: 12),
          const SizedBox(width: 10),
          Flexible(child: t(b, bold: bold, align: TextAlign.right)),
        ]),
      );

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Image.asset('assets/logo.png', width: 44, height: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  t(title, bold: true, size: 15, color: C.navy),
                  tl(context, j == null ? 'Taarifa za ada ya Kanda' : 'Taarifa za Jumuiya',
                      j == null ? 'Zone Fee Records' : 'Community Records', color: C.navy, size: 11),
                ]),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: cardBox(),
                child: Column(children: [
                  kv(tr('Idadi ya taarifa', 'Number of Records'), '${list.length}', bold: true),
                  kv(tr('Jumla ya ada', 'Total Fees'), 'TSh ${fmt(sum)}', bold: true),
                  const Divider(height: 14),
                  kv(tr('Kanda', 'Zone'), k.name),
                  kv(tr('Ada Kanda', 'Zone Fee'), kf > 0 ? 'TSh ${fmt(kf)}' : tr('Haijajazwa', 'Not entered')),
                  kv(tr('Jumla kuu ya Kanda', 'Zone Grand Total'), 'TSh ${fmt(app.kandaTotal(k))}'),
                ]),
              ),
              const SizedBox(height: 14),
              sectionTitle(tr('Taarifa zilizoingizwa (mpya kwanza)', 'Entered Records (newest first)')),
              for (final e in list)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: cardBox(),
                  child: Row(children: [
                    SizedBox(width: 150, child: t(e.noText, bold: true, size: 11)),
                    Expanded(child: t(dateText(e.date), size: 12, color: C.muted)),
                    t('TSh ${fmt(e.amount)}', bold: true, size: 13, color: C.navy),
                    const SizedBox(width: 4),
                    TextButton(onPressed: () => showRecordView(context, app, e), child: Text(tr('Angalia', 'View'))),
                  ]),
                ),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
              FilledButton.icon(
                onPressed: () => runExport(ctx, 'Taarifa_${(j ?? k.name).replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}', 'pdf', () => ExportService.entriesPdf(app, k, j)),
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(tr('Export PDF', 'Export PDF')),
              ),
              OutlinedButton.icon(
                onPressed: () => runExport(ctx, 'Taarifa_${(j ?? k.name).replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}', 'xlsx', () async => ExportService.entriesExcel(app, k, j)),
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: Text(tr('Export Excel', 'Export Excel')),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Funga', 'Close'))),
            ]),
          ),
        ]),
      ),
    ),
  );
}

void _showUnpaid(BuildContext context, AppState app, Kanda k, String? j) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(j ?? tr('Ada ya ${k.name}', 'Fee for ${k.name}')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tl(context,
              j == null ? 'Ada ya Kanda hii haijaingizwa bado.' : 'Jumuiya hii haijaweka ada bado.',
              j == null ? 'This zone fee has not been entered yet.' : 'This community has not paid yet.',
              color: C.amber, bold: true),
          const SizedBox(height: 10),
          tl(context, 'Kanda: ${k.name}', 'Zone: ${k.name}'),
          tl(context,
              'Ada ya Kanda: ${(app.kandaFee[k.name] ?? 0) > 0 ? 'TSh ${fmt(app.kandaFee[k.name]!)}' : 'haijajazwa'}',
              'Zone fee: ${(app.kandaFee[k.name] ?? 0) > 0 ? 'TSh ${fmt(app.kandaFee[k.name]!)}' : 'not entered'}'),
          tl(context, 'Jumla ya Kanda: TSh ${fmt(app.kandaTotal(k))}', 'Zone total: TSh ${fmt(app.kandaTotal(k))}'),
          const SizedBox(height: 10),
          tl(context,
              'Export itapatikana baada ya ada kuhifadhiwa kupitia Uingizaji wa Data.',
              'Export will be available after a fee is saved through Data Entry.',
              color: C.muted, size: 12),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Funga', 'Close')))],
    ),
  );
}
