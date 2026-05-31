import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Caches the PIN-derived vault key in the OS keystore/keychain so the vault
/// can be unlocked with biometrics (without re-entering the PIN).
class SecureKeyStore {
  SecureKeyStore._();
  static final SecureKeyStore instance = SecureKeyStore._();

  static const _keyName = 'bitanon_vault_key';
  static const _flagName = 'bitanon_biometric_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveKey(Uint8List key) async {
    await _storage.write(key: _keyName, value: base64.encode(key));
    await _storage.write(key: _flagName, value: 'true');
  }

  Future<Uint8List?> readKey() async {
    final v = await _storage.read(key: _keyName);
    if (v == null) return null;
    try {
      return base64.decode(v);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isEnabled async => (await _storage.read(key: _flagName)) == 'true';

  Future<void> clear() async {
    await _storage.delete(key: _keyName);
    await _storage.delete(key: _flagName);
  }
}
