import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PIN huhifadhiwa kama hash (SHA-256 + salt), si maandishi wazi.
class PinService {
  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';
  static const int minLength = 4;

  Future<bool> hasPin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kHash) != null;
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    await p.setString(_kSalt, salt);
    await p.setString(_kHash, _hash(pin, salt));
  }

  Future<bool> verify(String pin) async {
    final p = await SharedPreferences.getInstance();
    final salt = p.getString(_kSalt);
    final hash = p.getString(_kHash);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }
}
