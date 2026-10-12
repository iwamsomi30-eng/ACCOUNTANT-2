import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../l10n.dart';

class DashboardPage extends StatelessWidget {
  final AppState app;
  const DashboardPage({super.key, required this.app});

  /// Kadi ya rangi imara (maandishi meupe) - upana unapangwa na skrini.
  Widget _stat(double w, String label, String value, IconData icon, Color bg, bool narrow) =>
      Container(
        width: w,
        padding: EdgeInsets.all(narrow ? 18 : 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          CircleAvatar(
              radius: narrow ? 24 : 20,
              backgroundColor: Colors.white.withOpacity(.22),
              child: Icon(icon, size: narrow ? 25 : 21, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: narrow ? 13 : 11.5, color: const Color(0xE6FFFFFF))),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: narrow ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),
        ]),
      );

  Widget _bar(double fraction) => Stack(children: [
        Container(
            height: 14,
            decoration: BoxDecoration(color: C.head, borderRadius: BorderRadius.circular(7))),
        FractionallySizedBox(
          widthFactor: fraction,
          child: Container(
              height: 14,
              decoration:
                  BoxDecoration(color: C.cViolet, borderRadius: BorderRadius.circular(7))),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final totals = [for (final k in kSeedKanda) app.kandaTotal(k)];
    final maxV = totals.fold<int>(0, (a, b) => b > a ? b : a);
    final unpaid = app.unpaidJumuiya();

    return LayoutBuilder(builder: (context, pc) {
      final narrow = pc.maxWidth < kNarrow;
      return ListView(
        padding: EdgeInsets.fromLTRB(narrow ? 16 : 14, narrow ? 18 : 14, narrow ? 16 : 14, narrow ? 100 : 14),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              tl(context, 'Dashboard', 'Dashboard', bold: true, size: narrow ? 22 : 20),
              tl(context, 'Michango ${DateTime.now().year}', 'Contributions ${DateTime.now().year}', color: C.muted, size: 12),
            ],
          ),
          SizedBox(height: narrow ? 16 : 12),
          LayoutBuilder(builder: (context, cons) {
            final gap = narrow ? 14.0 : 12.0;
            final cols = cons.maxWidth >= 900 ? 4 : (cons.maxWidth >= 430 ? 2 : 1);
            final w = (cons.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              _stat(w, tr('Jumla ya Makusanyo', 'Total Collections'), 'TSh ${fmt(app.total)}', Icons.payments_outlined, C.cBlue, narrow),
              _stat(w, tr('Jumla ya Kanda', 'Total Zones'), '${kSeedKanda.length}', Icons.groups_outlined, C.cViolet, narrow),
              _stat(w, tr('Jumuiya zilizolipa', 'Communities Paid'), '${app.paidJumuiya} / ${app.jumuiyaCount}',
                  Icons.check_circle_outline, C.cGreen, narrow),
              _stat(w, tr('Risiti zilizotolewa', 'Receipts Issued'), '${app.receipts.length}', Icons.receipt_long, C.cOrange, narrow),
            ]);
          }),
          const SizedBox(height: 22),
          sectionTitle(tr('Makusanyo kwa Kanda', 'Collections by Zone')),
          Container(
            padding: EdgeInsets.all(narrow ? 16 : 12),
            decoration: cardBox(),
            child: Column(children: [
              for (var i = 0; i < kSeedKanda.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: narrow ? 9 : 5),
                  child: narrow
                      // Simu: jina na kiasi juu, mstari wa bar chini (upana kamili).
                      ? Column(children: [
                          Row(children: [
                            Expanded(child: t(kSeedKanda[i].name, size: 13.5)),
                            t(fmt(totals[i]), bold: true, size: 13.5),
                          ]),
                          const SizedBox(height: 8),
                          _bar(maxV == 0 ? 0 : totals[i] / maxV),
                        ])
                      : Row(children: [
                          SizedBox(width: 130, child: t(kSeedKanda[i].name, size: 12)),
                          Expanded(child: _bar(maxV == 0 ? 0 : totals[i] / maxV)),
                          SizedBox(
                              width: 90,
                              child: t(fmt(totals[i]), bold: true, size: 12, align: TextAlign.right)),
                        ]),
                ),
            ]),
          ),
          const SizedBox(height: 22),
          sectionTitle(tr('Jumuiya zisizo na ada (${unpaid.length})', 'Communities without fees (${unpaid.length})')),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(narrow ? 16 : 12),
            decoration: cardBox(),
            child: unpaid.isEmpty
                ? tl(context, 'Jumuiya zote zimeweka ada. Hongera!', 'All communities have paid. Great!', color: C.green)
                : Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final u in unpaid)
                      Chip(
                        label: Text(u, style: TextStyle(fontSize: narrow ? 12.5 : 11)),
                        backgroundColor: C.soft,
                        labelStyle: TextStyle(fontSize: narrow ? 12.5 : 11, color: C.text),
                        side: const BorderSide(color: C.border),
                        visualDensity: narrow ? VisualDensity.standard : VisualDensity.compact,
                      ),
                  ]),
          ),
        ],
      );
    });
  }
}
