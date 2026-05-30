import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// Full-width gradient primary button (height 54).
class PrimaryButton extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final bool disabled;

  const PrimaryButton({
    super.key,
    required this.theme,
    required this.label,
    this.icon,
    this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final off = disabled;
    return GestureDetector(
      onTap: off ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: off ? null : theme.accentGradient,
          color: off ? theme.surface2 : null,
          borderRadius: BorderRadius.circular(theme.buttonRadius),
          boxShadow: off
              ? null
              : [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.27),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 20, color: off ? theme.dim : theme.onAccent),
              const SizedBox(width: 9),
            ],
            Text(
              label,
              style: theme.ui(
                size: 16.5,
                weight: FontWeight.w700,
                color: off ? theme.dim : theme.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width outlined "ghost" button (height 52).
class GhostButton extends StatelessWidget {
  final AppTheme theme;
  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const GhostButton({
    super.key,
    required this.theme,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.text;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.buttonRadius),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 20, color: c),
              const SizedBox(width: 9),
            ],
            Text(label, style: theme.ui(size: 15.5, weight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}

/// An iOS-style toggle switch.
class AppToggle extends StatelessWidget {
  final AppTheme theme;
  final bool value;
  final VoidCallback onChanged;

  const AppToggle({
    super.key,
    required this.theme,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? theme.accent : theme.surface2,
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
