import 'package:flutter/material.dart';

import '../models/account.dart';
import 'totp.dart';

/// Parses `otpauth://totp/...` URIs (the QR/manual format) into [Account]s,
/// and assigns a deterministic brand color.
class OtpAuth {
  OtpAuth._();

  /// A spread of pleasant brand-ish colors; chosen deterministically per issuer
  /// so the same service always gets the same tile color.
  static const List<Color> _palette = [
    Color(0xFF4285F4), Color(0xFF1652F0), Color(0xFFFF9900), Color(0xFF0061FF),
    Color(0xFF5865F2), Color(0xFFF6821F), Color(0xFFA259FF), Color(0xFFF0B90B),
    Color(0xFF611F69), Color(0xFF635BFF), Color(0xFF0070E0), Color(0xFF9146FF),
    Color(0xFF34D399), Color(0xFFF43F5E), Color(0xFF6366F1),
  ];

  static Color colorForIssuer(String issuer) {
    if (issuer.isEmpty) return _palette[0];
    var h = 0;
    for (final u in issuer.toLowerCase().codeUnits) {
      h = (h * 31 + u) & 0x7FFFFFFF;
    }
    return _palette[h % _palette.length];
  }

  static String normalizeAlgorithm(String? raw) {
    switch ((raw ?? '').toUpperCase().replaceAll('-', '')) {
      case 'SHA256':
        return 'SHA-256';
      case 'SHA512':
        return 'SHA-512';
      default:
        return 'SHA-1';
    }
  }

  /// Returns an [Account] from an otpauth URI, or null if it isn't a valid
  /// TOTP setup URI with a usable secret.
  static Account? parse(String raw, {String? id}) {
    Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return null;
    }
    if (uri.scheme.toLowerCase() != 'otpauth') return null;
    if (uri.host.toLowerCase() != 'totp') return null; // HOTP not supported

    final secret = uri.queryParameters['secret'] ?? '';
    if (!Totp.isValidSecret(secret)) return null;

    // Path is "/Issuer:Account" or "/Account".
    var path = uri.path;
    if (path.startsWith('/')) path = path.substring(1);
    path = Uri.decodeComponent(path);
    String issuer = uri.queryParameters['issuer'] ?? '';
    String label = path;
    if (path.contains(':')) {
      final parts = path.split(':');
      if (issuer.isEmpty) issuer = parts.first.trim();
      label = parts.sublist(1).join(':').trim();
    }
    if (issuer.isEmpty) issuer = label.isEmpty ? 'Account' : label;

    final digits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6;
    final period = int.tryParse(uri.queryParameters['period'] ?? '') ?? 30;

    return Account(
      id: id ?? 'otp${DateTime.now().microsecondsSinceEpoch}',
      issuer: issuer,
      label: label.isEmpty ? issuer : label,
      secret: secret.replaceAll(RegExp(r'\s'), '').toUpperCase(),
      logo: issuer.toLowerCase(),
      color: colorForIssuer(issuer),
      period: period,
      digits: digits == 8 ? 8 : 6,
      algorithm: normalizeAlgorithm(uri.queryParameters['algorithm']),
    );
  }
}
