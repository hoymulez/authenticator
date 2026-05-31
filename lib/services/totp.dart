import 'dart:typed_data';

import 'package:hashlib/hashlib.dart' show BlockHashBase, HOTP, sha1, sha256, sha512;
import 'package:hashlib/codecs.dart' show fromBase32;

import '../models/account.dart';

/// Real RFC 6238 TOTP generation backed by **hashlib** (HMAC-SHA + dynamic
/// truncation over a base32-decoded secret).
///
/// The time-window math (window/remaining/progress) is computed directly so
/// the countdown UI ticks smoothly; the code itself comes from hashlib's HOTP
/// with the time counter, which is exactly TOTP.
class Totp {
  const Totp._();

  static int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Counter for the current period window.
  static int window(int period) => _nowSeconds() ~/ period;

  /// Whole seconds remaining in the current window.
  static int remaining(int period) => period - (_nowSeconds() % period);

  /// Fraction of the window remaining, 1.0 → 0.0.
  static double progress(int period) {
    final ms = DateTime.now().millisecondsSinceEpoch / 1000.0;
    return 1 - (ms % period) / period;
  }

  static BlockHashBase _algo(String a) {
    switch (a.toUpperCase().replaceAll('-', '')) {
      case 'SHA256':
        return sha256;
      case 'SHA512':
        return sha512;
      default:
        return sha1;
    }
  }

  /// Decode a base32 secret to bytes, tolerating spaces, lowercase and missing
  /// padding. Returns null if it isn't valid base32.
  static Uint8List? decodeSecret(String secret) {
    var s = secret.replaceAll(RegExp(r'\s'), '').replaceAll('=', '').toUpperCase();
    if (s.isEmpty) return null;
    while (s.length % 8 != 0) {
      s += '=';
    }
    try {
      final bytes = fromBase32(s);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  static Uint8List _counterBytes(int counter) {
    final c = Uint8List(8);
    var x = counter;
    for (int i = 7; i >= 0; i--) {
      c[i] = x & 0xFF;
      x >>= 8;
    }
    return c;
  }

  static String _code(String secret, int counter, int digits, String algorithm) {
    final bytes = decodeSecret(secret);
    if (bytes == null) return '-' * digits;
    return HOTP(
      bytes,
      counter: _counterBytes(counter),
      algo: _algo(algorithm),
      digits: digits,
    ).valueString();
  }

  /// True when the account's secret is valid base32.
  static bool isValidSecret(String secret) => decodeSecret(secret) != null;

  /// Current code for an account.
  static String codeFor(Account a) => _code(a.secret, window(a.period), a.digits, a.algorithm);

  /// Code for the next window (detail "Next" preview).
  static String next(Account a) => _code(a.secret, window(a.period) + 1, a.digits, a.algorithm);

  /// Code for arbitrary parameters (manual-entry live preview).
  static String preview(String secret, int period, int digits, [String algorithm = 'SHA-1']) =>
      _code(secret.replaceAll(RegExp(r'\s'), ''), window(period), digits, algorithm);

  /// Group digits: 6 → `NNN NNN`, 8 → `NNNN NNNN`.
  static String format(String code) {
    if (code.length == 6) return '${code.substring(0, 3)} ${code.substring(3)}';
    if (code.length == 8) return '${code.substring(0, 4)} ${code.substring(4)}';
    return code;
  }
}
