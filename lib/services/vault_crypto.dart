import 'dart:convert';
import 'dart:typed_data';

import 'package:cipherlib/cipherlib.dart' show AES;
import 'package:hashlib/hashlib.dart' show pbkdf2;
import 'package:hashlib/random.dart' show randomBytes;

/// End-to-end encryption for the local vault and backups, using
/// **hashlib** (PBKDF2 key derivation) + **cipherlib** (AES-256-GCM).
///
/// Blob layout (then base64): `salt(16) | iv(12) | ciphertext+tag`.
/// The salt is embedded so a blob is self-contained: any holder of the PIN can
/// decrypt it, which is what makes the exported `.enc` file portable.
class VaultCrypto {
  VaultCrypto._();

  static const int _iterations = 120000;
  static const int saltLen = 16;
  static const int _ivLen = 12;
  static const int keyLen = 32; // AES-256

  static Uint8List newSalt() => randomBytes(saltLen);

  /// PBKDF2-HMAC-SHA256(pin, salt) → 32-byte AES key.
  static Uint8List deriveKey(String pin, List<int> salt) {
    final digest = pbkdf2(utf8.encode(pin), salt, _iterations, keyLen);
    return Uint8List.fromList(digest.bytes);
  }

  /// Encrypts [plaintext] with [key]; embeds [salt] so the blob is portable.
  static String encrypt(String plaintext, Uint8List key, Uint8List salt) {
    final iv = randomBytes(_ivLen);
    final ct = AES(key).gcm(iv).encrypt(utf8.encode(plaintext));
    final blob = Uint8List(salt.length + iv.length + ct.length);
    blob.setRange(0, salt.length, salt);
    blob.setRange(salt.length, salt.length + iv.length, iv);
    blob.setRange(salt.length + iv.length, blob.length, ct);
    return base64.encode(blob);
  }

  /// Convenience: derive a key from [pin] with a fresh salt and encrypt.
  /// Used for the portable export file.
  static String encryptWithPin(String plaintext, String pin) {
    final salt = newSalt();
    final key = deriveKey(pin, salt);
    return encrypt(plaintext, key, salt);
  }

  /// Decrypts a blob using [pin] (re-derives the key from the embedded salt).
  /// Throws if the PIN is wrong (GCM tag mismatch) or the blob is malformed.
  static DecryptedVault decryptWithPin(String blobB64, String pin) {
    final blob = base64.decode(blobB64);
    final salt = Uint8List.sublistView(blob, 0, saltLen);
    final iv = Uint8List.sublistView(blob, saltLen, saltLen + _ivLen);
    final ct = Uint8List.sublistView(blob, saltLen + _ivLen);
    final key = deriveKey(pin, salt);
    final plain = AES(key).gcm(iv).decrypt(ct);
    return DecryptedVault(utf8.decode(plain), key, salt);
  }

  /// Decrypts a blob with a pre-derived [key] (biometric unlock path).
  static String decryptWithKey(String blobB64, Uint8List key) {
    final blob = base64.decode(blobB64);
    final iv = Uint8List.sublistView(blob, saltLen, saltLen + _ivLen);
    final ct = Uint8List.sublistView(blob, saltLen + _ivLen);
    final plain = AES(key).gcm(iv).decrypt(ct);
    return utf8.decode(plain);
  }
}

class DecryptedVault {
  final String json;
  final Uint8List key;
  final Uint8List salt;
  const DecryptedVault(this.json, this.key, this.salt);
}
