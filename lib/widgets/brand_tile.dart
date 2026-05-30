import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';

/// A rounded brand tile: the issuer's color with a monogram glyph.
///
/// The prototype draws simplified abstract brand marks; per the handoff these
/// are placeholders and a colored monogram tile is the sanctioned fallback.
class BrandTile extends StatelessWidget {
  final Account account;
  final double size;
  final double radius;

  const BrandTile({
    super.key,
    required this.account,
    this.size = 44,
    this.radius = 13,
  });

  @override
  Widget build(BuildContext context) {
    final color = account.color;
    final light = _luminance(color) > 0.62;
    final fg = light ? const Color(0xEB14161C) : Colors.white;
    final bg = light ? color : Color.lerp(color, Colors.black, 0.10)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        _monogram(account.issuer),
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1,
        ),
      ),
    );
  }

  static String _monogram(String issuer) {
    final trimmed = issuer.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  static double _luminance(Color c) {
    final r = (c.r * 255.0).round() / 255.0;
    final g = (c.g * 255.0).round() / 255.0;
    final b = (c.b * 255.0).round() / 255.0;
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }
}

/// Clamps a value into [0, 1].
double clamp01(double v) => math.max(0.0, math.min(1.0, v));
