import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../l10n.dart';

class SecurityPage extends StatefulWidget {
  final PinService pin;
  final VoidCallback onLock;
  const SecurityPage({super.key, required this.pin, required this.onLock});
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _again = TextEditingController();
  String? _msg;
  bool _ok = false;

  Future<void> _change() async {
    if (!await widget.pin.verify(_old.text.trim())) {
      return setState(() { _msg = tr('PIN ya sasa si sahihi', 'Current PIN is incorrect'); _ok = false; });
    }
    if (_new.text.trim().length < PinService.minLength) {
      return setState(() { _msg = tr('PIN mpya iwe angalau tarakimu ${PinService.minLength}', 'New PIN must be at least ${PinService.minLength} digits'); _ok = false; });
    }
    if (_new.text.trim() != _again.text.trim()) {
      return setState(() { _msg = tr('PIN mpya hazilingani', 'New PINs do not match'); _ok = false; });
    }
    await widget.pin.setPin(_new.text.trim());
    _old.clear(); _new.clear(); _again.clear();
    setState(() { _msg = tr('PIN imebadilishwa', 'PIN changed successfully'); _ok = true; });
  }

  Widget _f(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: InputDecoration(
              labelText: label, counterText: ''),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      tl(context, 'Usalama wa PIN', 'Security PIN', bold: true, size: 20),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle(tr('Badilisha PIN', 'Change PIN')),
          _f(tr('PIN ya sasa', 'Current PIN'), _old),
          _f(tr('PIN mpya', 'New PIN'), _new),
          _f(tr('Rudia PIN mpya', 'Confirm New PIN'), _again),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: t(_msg!, color: _ok ? C.green : C.danger, size: 12),
            ),
          FilledButton(
            onPressed: _change,
            style: FilledButton.styleFrom(backgroundColor: C.btn),
            child: Text(tr('Hifadhi PIN mpya', 'Save New PIN')),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle(tr('Funga app', 'Lock App')),
          tl(context, 'App hujifunga yenyewe ukiiacha dakika 30. Unaweza kuifunga sasa.', 'The app locks automatically after 30 minutes of inactivity. You can lock it now.',
              color: C.muted, size: 12),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onLock,
            icon: const Icon(Icons.lock_outline, size: 18),
            label: Text(tr('Funga sasa', 'Lock Now')),
          ),
        ]),
      ),
    ]);
  }
}
