import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/pin_service.dart';
import '../l10n.dart';
import '../widgets/church_background.dart';

/// Skrini ya PIN: kuweka PIN mara ya kwanza, au kuingia (login).
class PinScreen extends StatefulWidget {
  final PinService pinService;
  final bool isSetup;
  final VoidCallback onSuccess;
  const PinScreen({
    super.key,
    required this.pinService,
    required this.isSetup,
    required this.onSuccess,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    final pin = _pin.text.trim();
    if (widget.isSetup) {
      if (pin.length < PinService.minLength) {
        setState(() => _error = tr('PIN iwe angalau tarakimu ${PinService.minLength}', 'PIN must be at least ${PinService.minLength} digits'));
        return;
      }
      if (pin != _confirm.text.trim()) {
        setState(() => _error = tr('PIN hazilingani', 'PINs do not match'));
        return;
      }
      await widget.pinService.setPin(pin);
      widget.onSuccess();
    } else {
      if (await widget.pinService.verify(pin)) {
        widget.onSuccess();
      } else {
        setState(() {
          _error = tr('PIN si sahihi', 'Incorrect PIN');
          _pin.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bgDeep,
      body: ChurchBackground(child: Stack(
        children: [
          const Positioned(top: 18, right: 18, child: LanguageSwitcher()),
          Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: C.card,
                  border: Border.all(color: C.border, width: .8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
                  ]),
              child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Image.asset('assets/logo.png', width: 96, height: 96),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(widget.isSetup ? 'Weka PIN Mpya' : 'Ingiza PIN Kuingia', widget.isSetup ? 'Set New PIN' : 'Enter PIN to Sign In'),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: C.text),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      labelText: tr('PIN', 'PIN')),
                  onSubmitted: (_) {
                    if (!widget.isSetup) _submit();
                  },
                ),
                if (widget.isSetup) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        labelText: tr('Rudia PIN', 'Confirm PIN')),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_error!,
                        style: const TextStyle(color: C.danger)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: C.btn),
                    child: Text(tr(widget.isSetup ? 'HIFADHI PIN' : 'INGIA', widget.isSetup ? 'SAVE PIN' : 'SIGN IN')),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
        ),
        ],
      )),
    );
  }
}
