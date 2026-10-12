import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n.dart';
import '../widgets/church_background.dart';

/// Inaonyesha logo wakati app inafunguka.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ChurchBackground.preload(context);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bgDeep,
      body: ChurchBackground(child: Stack(
        children: [
          const Positioned(top: 18, right: 18, child: LanguageSwitcher()),
          Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Image.asset('assets/logo.png', width: 150, height: 150),
            ),
            const SizedBox(height: 24),
            Text(tr('MFUMO WA MAKUSANYO YA PESA', 'COLLECTIONS MANAGEMENT SYSTEM'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 28),
            const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
          ],
        ),
        ),
        ],
      )),
    );
  }
}
