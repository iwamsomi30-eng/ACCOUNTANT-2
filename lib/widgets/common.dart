import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n.dart';

Text t(String s, {bool bold = false, Color? color, double size = 13, TextAlign? align}) =>
    Text(s,
        textAlign: align,
        style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: color ?? C.text));

/// Kila seli ina nafasi pembeni (padding) ili maandishi yasibanane.
Widget cell(Widget child, {double? w}) {
  final padded = Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: child);
  return w != null ? SizedBox(width: w, child: padded) : Expanded(child: padded);
}

Widget gridRow(List<Widget> cells, {bool header = false, bool total = false}) =>
    Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: header ? 9 : 6),
      decoration: BoxDecoration(
        color: header ? C.head : (total ? C.cardAlt : C.card),
        border: const Border(
            bottom: BorderSide(color: C.border, width: .6)),
      ),
      child: Row(children: cells),
    );

Widget sectionTitle(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: t(s, bold: true, color: C.text, size: 14),
    );

BoxDecoration cardBox() => BoxDecoration(
      color: C.card,
      border: Border.all(color: C.border, width: .8),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
      ],
    );

Text tl(BuildContext context, String swahili, String english, {bool bold = false, Color? color, double size = 13, TextAlign? align}) => trText(swahili, english, bold: bold, color: color ?? C.text, size: size, align: align);

/// Upana (dp) chini ya huu = skrini nyembamba (simu). Tunatumia kadi zenye nafasi
/// badala ya jedwali lenye safu nyingi, ili maandishi yasibanane.
const double kNarrow = 560;
