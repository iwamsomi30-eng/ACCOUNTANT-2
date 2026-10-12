import 'package:flutter/material.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/pin_screen.dart';
import 'screens/splash_screen.dart';
import 'services/pin_service.dart';
import 'l10n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MakusanyoApp());
}

enum _Stage { splash, pinSetup, pinLogin, home }

class MakusanyoApp extends StatefulWidget {
  const MakusanyoApp({super.key});
  @override
  State<MakusanyoApp> createState() => _MakusanyoAppState();
}

class _MakusanyoAppState extends State<MakusanyoApp>
    with WidgetsBindingObserver {
  static const lockAfter = Duration(minutes: 30);
  final _pinService = PinService();
  final _app = AppState();
  _Stage _stage = _Stage.splash;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LanguageController.shared.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Mtumiaji akiacha app (background/minimize) dakika 30, PIN inaombwa tena.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (left != null &&
          _stage == _Stage.home &&
          DateTime.now().difference(left) >= lockAfter) {
        setState(() => _stage = _Stage.pinLogin);
      }
    }
  }

  Future<void> _afterSplash() async {
    await _app.load();
    final has = await _pinService.hasPin();
    setState(() => _stage = has ? _Stage.pinLogin : _Stage.pinSetup);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.shared,
      builder: (context, _) {
        Widget screen;
    switch (_stage) {
      case _Stage.splash:
        screen = SplashScreen(onDone: _afterSplash);
      case _Stage.pinSetup:
        screen = PinScreen(
            pinService: _pinService,
            isSetup: true,
            onSuccess: () => setState(() => _stage = _Stage.home));
      case _Stage.pinLogin:
        screen = PinScreen(
            pinService: _pinService,
            isSetup: false,
            onSuccess: () => setState(() => _stage = _Stage.home));
      case _Stage.home:
        screen = Shell(
            app: _app,
            pin: _pinService,
            onLock: () => setState(() => _stage = _Stage.pinLogin));
    }
        return MaterialApp(
          title: tr('Mfumo wa Makusanyo ya Pesa', 'Collections Management System'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: screen,
        );
      },
    );
  }
}
