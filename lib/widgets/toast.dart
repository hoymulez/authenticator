import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

OverlayEntry? _activeToast;

/// Shows a centered pill toast near the bottom of the screen.
void showAppToast(BuildContext context, AppTheme theme, String message) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _activeToast?.remove();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastWidget(
      theme: theme,
      message: message,
      onDismissed: () {
        if (_activeToast == entry) _activeToast = null;
        entry.remove();
      },
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final AppTheme theme;
  final String message;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.theme,
    required this.message,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1600), () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final curve = CurvedAnimation(parent: _c, curve: const Cubic(0.32, 0.72, 0, 1));
    return Positioned(
      left: 0,
      right: 0,
      bottom: 96,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: curve,
            builder: (context, child) {
              return Opacity(
                opacity: curve.value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - curve.value)),
                  child: Transform.scale(scale: 0.96 + 0.04 * curve.value, child: child),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: theme.dark
                    ? const Color(0xFF1C1F27).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.borderHi),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 10)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon('check', size: 18, color: theme.accent),
                  const SizedBox(width: 10),
                  Text(widget.message,
                      style: theme.ui(size: 14, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
