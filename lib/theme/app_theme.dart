// Design tokens for Bitanon Authenticator — ported from the design handoff.
//
// Colors, typography, spacing, radii and motion mirror the HTML/React
// prototype's `makeTheme` so the native UI matches the design closely.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// How the per-account countdown is rendered.
enum CountdownStyle { logo, border, ring, bar }

/// List density.
enum Density { comfortable, compact }

/// User-selectable accent colors (first is the default amber).
const List<Color> kAccentOptions = [
  Color(0xFFF59E0B),
  Color(0xFF6366F1),
  Color(0xFF22D3A6),
  Color(0xFF34D399),
  Color(0xFFF43F5E),
];

/// Immutable bundle of resolved design tokens. Rebuilt whenever a setting
/// (theme, accent, countdown style, density, radius) changes.
class AppTheme {
  final bool dark;
  final Color accent;
  final CountdownStyle countdown;
  final Density density;
  final double radius;

  const AppTheme({
    this.dark = true,
    this.accent = const Color(0xFFF59E0B),
    this.countdown = CountdownStyle.logo,
    this.density = Density.comfortable,
    this.radius = 22,
  });

  AppTheme copyWith({
    bool? dark,
    Color? accent,
    CountdownStyle? countdown,
    Density? density,
    double? radius,
  }) {
    return AppTheme(
      dark: dark ?? this.dark,
      accent: accent ?? this.accent,
      countdown: countdown ?? this.countdown,
      density: density ?? this.density,
      radius: radius ?? this.radius,
    );
  }

  bool get isCompact => density == Density.compact;

  @override
  bool operator ==(Object other) =>
      other is AppTheme &&
      other.dark == dark &&
      other.accent == accent &&
      other.countdown == countdown &&
      other.density == density &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(dark, accent, countdown, density, radius);

  // ── Accent derivatives ──────────────────────────────────────
  /// accent @ 16% — soft fills (chips, icon wells).
  Color get accentSoft => accent.withValues(alpha: 0.16);

  /// accent mixed 75% with white — gradient top stop on buttons.
  Color get accentHi => Color.lerp(Colors.white, accent, 0.75)!;

  // ── Surfaces & text ─────────────────────────────────────────
  Color get bg => dark ? const Color(0xFF0A0B0E) : const Color(0xFFF1F1F3);
  Color get surface => dark ? const Color(0xFF15171D) : const Color(0xFFFFFFFF);
  Color get surface2 => dark ? const Color(0xFF1C1F27) : const Color(0xFFF6F6F8);
  Color get surfaceHi => dark ? const Color(0xFF232732) : const Color(0xFFFFFFFF);
  Color get border =>
      dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F0F14).withValues(alpha: 0.08);
  Color get borderHi =>
      dark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFF0F0F14).withValues(alpha: 0.14);
  Color get text => dark ? const Color(0xFFF4F4F2) : const Color(0xFF16181D);
  Color get muted => text.withValues(alpha: 0.56);
  Color get dim => text.withValues(alpha: dark ? 0.34 : 0.40);

  static const Color danger = Color(0xFFF0556B);
  static const Color success = Color(0xFF34D399);

  /// Text color that sits on top of the accent (buttons, FAB, selected segs).
  Color get onAccent => dark ? const Color(0xFF0A0B0E) : const Color(0xFF1A1205);

  /// Radial background gradient behind every screen.
  Gradient get bgGradient => RadialGradient(
        center: const Alignment(0, -1.2),
        radius: 1.3,
        colors: dark
            ? const [Color(0xFF15171E), Color(0xFF0A0B0E)]
            : const [Color(0xFFFFFFFF), Color(0xFFECECEF)],
        stops: const [0.0, 0.55],
      );

  /// Vertical accent gradient for primary buttons / FAB.
  Gradient get accentGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accentHi, accent],
      );

  // ── Radii derived from base radius ──────────────────────────
  double get buttonRadius => radius * 0.8;
  double get tileRadius => radius * 0.5;

  // ── Typography ──────────────────────────────────────────────
  TextStyle ui({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color ?? text,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle mono({
    double size = 15,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double letterSpacing = 0,
    double height = 1.2,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? text,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Standard horizontal screen padding.
  static const double screenPad = 18;
}

/// Holds mutable app appearance settings and notifies listeners on change.
class ThemeController extends ChangeNotifier {
  AppTheme _theme = const AppTheme();
  AppTheme get theme => _theme;

  void setDark(bool v) => _update(_theme.copyWith(dark: v));
  void setAccent(Color c) => _update(_theme.copyWith(accent: c));
  void setCountdown(CountdownStyle c) => _update(_theme.copyWith(countdown: c));
  void setDensity(Density d) => _update(_theme.copyWith(density: d));
  void setRadius(double r) => _update(_theme.copyWith(radius: r));

  void _update(AppTheme next) {
    _theme = next;
    notifyListeners();
  }
}
