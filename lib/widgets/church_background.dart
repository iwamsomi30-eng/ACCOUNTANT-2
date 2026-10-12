import 'package:flutter/material.dart';

/// Picha ya kanisa kama mandhari ya skrini zinazoonekana wakati app inafunguka
/// (Splash na PIN) hadi ukurasa wa Home utakapotokea.
/// Inatumia rangi ya navy nusu-uwazi juu ya picha (si gradient) ili maandishi
/// yasomeke vizuri na ionekane sawa kwenye Windows na Android.
class ChurchBackground extends StatelessWidget {
  final Widget child;
  const ChurchBackground({super.key, required this.child});

  static const asset = 'assets/church_bg.png';

  /// Inapakia picha mapema ili ionekane papo hapo.
  static Future<void> preload(BuildContext context) =>
      precacheImage(const AssetImage(asset), context);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0C1030)),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const ColoredBox(color: Color(0xCC0C1030)),
        child,
      ],
    );
  }
}
