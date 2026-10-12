import 'package:flutter/material.dart';
import '../data/seed_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/record_view.dart';
import '../l10n.dart';

/// Taarifa za Jumuiya moja moja (na Kanda zake). Kila moja ina View na Export.
class JumuiyaPage extends StatefulWidget {
  final AppState app;
  const JumuiyaPage({super.key, required this.app});
  @override
  State<JumuiyaPage> createState() => _JumuiyaPageState();
}

class _JumuiyaPageState extends State<JumuiyaPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final q = _q.toLowerCase();
    return LayoutBuilder(builder: (context, cons) {
    final narrow = cons.maxWidth < kNarrow;
    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 14, narrow ? 18 : 14, narrow ? 16 : 14, narrow ? 100 : 14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tl(context, 'Jumuiya', 'Communities', bold: true, size: 18),
            tl(context, 'Zilizolipa ${app.paidJumuiya} / ${app.jumuiyaCount}', 'Paid ${app.paidJumuiya} / ${app.jumuiyaCount}', color: C.muted, size: 12),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 18),
            hintText: tr('Tafuta jumuiya au kanda', 'Search community or zone'),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: C.border)),
          ),
        ),
        const SizedBox(height: 12),
        for (final k in kSeedKanda)
          ..._section(app, k, q, narrow),
      ],
    );
    });
  }

  List<Widget> _section(AppState app, Kanda k, String q, bool narrow) {
    final kandaMatch = k.name.toLowerCase().contains(q);
    final js = k.jumuiya.where((j) => q.isEmpty || kandaMatch || j.toLowerCase().contains(q)).toList();
    if (js.isEmpty) return [];
    final kf = app.kandaFee[k.name] ?? 0;
    return [
      Container(
        margin: const EdgeInsets.only(top: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: narrow ? 12 : 8),
        decoration: const BoxDecoration(
          color: C.cHeader,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                  tr('Ada ya Kanda: ${kf > 0 ? 'TSh ${fmt(kf)}' : 'haijajazwa'}  |  Jumla ya Kanda: TSh ${fmt(app.kandaTotal(k))}', 'Zone fee: ${kf > 0 ? 'TSh ${fmt(kf)}' : 'not entered'}  |  Zone total: TSh ${fmt(app.kandaTotal(k))}'),
                  style: const TextStyle(color: Color(0xFFDCE6F2), fontSize: 11)),
            ]),
          ),
          TextButton(
            onPressed: () => showKandaView(context, app, k),
            child: Text(tr('Angalia Kanda', 'View Zone'), style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ]),
      ),
      for (var i = 0; i < js.length; i++)
        Builder(builder: (_) {
          final amount = app.jumuiyaFee[AppState.jKey(k.name, js[i])] ?? 0;
          final count = app.entriesFor(k.name, js[i]).length;
          final paid = amount > 0;
          if (narrow) {
            // Simu: jina na idadi ya taarifa kushoto, kiasi na kitufe kulia (nafasi kubwa).
            return Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              decoration: const BoxDecoration(
                color: C.card,
                border: Border(bottom: BorderSide(color: C.border, width: .6)),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    t(js[i], size: 14),
                    const SizedBox(height: 2),
                    t(count > 0 ? tr('Taarifa $count', '$count records') : tr('Hakuna taarifa', 'No records'), size: 11.5, color: C.muted),
                  ]),
                ),
                const SizedBox(width: 8),
                paid
                    ? t('TSh ${fmt(amount)}', bold: true, color: C.navy, size: 14, align: TextAlign.right)
                    : tl(context, 'Haijalipa', 'Not paid', color: C.amber, size: 13, align: TextAlign.right),
                IconButton(
                  tooltip: tr('Angalia', 'View'),
                  onPressed: () => showJumuiyaView(context, app, k, js[i]),
                  icon: const Icon(Icons.visibility_outlined, size: 22),
                ),
              ]),
            );
          }
          return gridRow([
            cell(t('${k.jumuiya.indexOf(js[i]) + 1}', color: C.muted), w: 48),
            cell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              t(js[i]),
              t(count > 0 ? tr('Taarifa $count', '$count records') : tr('Hakuna taarifa', 'No records'), size: 11, color: C.muted),
            ])),
            cell(
              paid
                  ? t('TSh ${fmt(amount)}', bold: true, color: C.navy, align: TextAlign.right)
                  : tl(context, 'Haijalipa', 'Not paid', color: C.amber, align: TextAlign.right),
              w: 130,
            ),
            cell(
              TextButton.icon(
                onPressed: () => showJumuiyaView(context, app, k, js[i]),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text(tr('Angalia', 'View')),
              ),
              w: 100,
            ),
          ]);
        }),
      const SizedBox(height: 10),
    ];
  }
}
