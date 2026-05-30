import '../models/account.dart';

/// TOTP code generation.
///
/// This ports the prototype's *deterministic simulation* so the UI behaves
/// exactly like the design (codes regenerate every period, countdown drains).
/// For a production build, swap [_genCode] for a real RFC 6238 implementation
/// backed by `hashlib` (HMAC-SHA + dynamic truncation over a base32 secret).
/// Everything else (windows, remaining, formatting) stays the same.
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

  /// Deterministic pseudo-code (FNV-1a + a mix pass) for a secret + window.
  static String _genCode(String secret, int win, int digits) {
    int h = 2166136261 & 0xFFFFFFFF;
    final s = '$secret|$win';
    for (int i = 0; i < s.length; i++) {
      h ^= s.codeUnitAt(i);
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    h ^= h >> 13;
    h = (h * 0x5bd1e995) & 0xFFFFFFFF;
    h ^= h >> 15;
    final mod = _pow10(digits);
    final code = (h & 0xFFFFFFFF) % mod;
    return code.toString().padLeft(digits, '0');
  }

  static int _pow10(int n) {
    int r = 1;
    for (int i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  /// Current code for an account.
  static String codeFor(Account a) => _genCode(a.secret, window(a.period), a.digits);

  /// Code for the *next* window (used by the detail "Next" preview).
  static String next(Account a) => _genCode(a.secret, window(a.period) + 1, a.digits);

  /// Code for an arbitrary secret/period/digits (manual-entry live preview).
  static String preview(String secret, int period, int digits) =>
      _genCode(secret.replaceAll(RegExp(r'\s'), ''), window(period), digits);

  /// Group digits: 6 → `NNN NNN`, 8 → `NNNN NNNN`.
  static String format(String code) {
    if (code.length == 6) return '${code.substring(0, 3)} ${code.substring(3)}';
    if (code.length == 8) return '${code.substring(0, 4)} ${code.substring(4)}';
    return code;
  }
}
