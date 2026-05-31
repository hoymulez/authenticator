import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/app_scope.dart';
import '../widgets/gradient_scaffold.dart';

enum PinMode { unlock, create, confirm }

class PinScreen extends StatefulWidget {
  final PinMode mode;

  /// Return false to trigger an error shake; true accepts the PIN.
  final Future<bool> Function(String pin) onComplete;
  final VoidCallback? onBiometric;
  final VoidCallback? onCancel;

  const PinScreen({
    super.key,
    required this.mode,
    required this.onComplete,
    this.onBiometric,
    this.onCancel,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _error = false;
  bool _checking = false;
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  static const Map<PinMode, List<String>> _titles = {
    PinMode.unlock: ['Enter your PIN', 'Unlock Bitanon to view your codes'],
    PinMode.create: ['Create a PIN', 'Choose a 6-digit code to lock your vault'],
    PinMode.confirm: ['Confirm your PIN', 'Re-enter the code to confirm'],
  };

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _digit(String d) {
    if (_pin.length >= 6 || _error || _checking) return;
    setState(() => _pin += d);
    if (_pin.length == 6) {
      _checking = true;
      Future.delayed(const Duration(milliseconds: 140), () async {
        if (!mounted) return;
        final ok = await widget.onComplete(_pin);
        _checking = false;
        if (!mounted) return;
        if (!ok) {
          setState(() => _error = true);
          _shake.forward(from: 0);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _error = false;
                _pin = '';
              });
            }
          });
        } else {
          setState(() => _pin = '');
        }
      });
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppScope.themeOf(context);
    final t = _titles[widget.mode]!;

    return GradientScaffold(
      theme: theme,
      safeBottom: true,
      child: Stack(
        children: [
          if (widget.onCancel != null)
            Positioned(
              top: 10,
              left: 20,
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Text('Cancel',
                    style: theme.ui(size: 15, weight: FontWeight.w600, color: theme.accent)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 56, 26, 24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: theme.accentSoft,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon('shield', size: 32, color: theme.accent),
                      ),
                      const SizedBox(height: 22),
                      Text(t[0], style: theme.ui(size: 23, weight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          t[1],
                          textAlign: TextAlign.center,
                          style: theme.ui(size: 14, weight: FontWeight.w400, color: theme.muted),
                        ),
                      ),
                      const SizedBox(height: 34),
                      _dots(theme),
                    ],
                  ),
                ),
                _keypad(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dots(AppTheme theme) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = _error
            ? math.sin(_shake.value * math.pi * 8) * 8 * (1 - _shake.value)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final filled = i < _pin.length;
          final c = _error ? AppTheme.danger : theme.accent;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? c : Colors.transparent,
              border: Border.all(color: filled ? c : theme.borderHi, width: 2),
            ),
          );
        }),
      ),
    );
  }

  Widget _keypad(AppTheme theme) {
    Widget key(Widget child, VoidCallback? onTap, {bool flat = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: flat ? Colors.transparent : theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: flat ? null : Border.all(color: theme.border),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      );
    }

    Widget digit(String d) => key(
          Text(d, style: theme.ui(size: 26, weight: FontWeight.w600)),
          () => _digit(d),
        );

    final bio = widget.mode == PinMode.unlock && widget.onBiometric != null;

    return Column(
      children: [
        Row(children: [digit('1'), digit('2'), digit('3')]),
        Row(children: [digit('4'), digit('5'), digit('6')]),
        Row(children: [digit('7'), digit('8'), digit('9')]),
        Row(
          children: [
            key(
              bio ? AppIcon('faceid', size: 30, color: theme.accent) : const SizedBox.shrink(),
              bio ? widget.onBiometric : null,
              flat: true,
            ),
            digit('0'),
            key(
              AppIcon('chevL', size: 26, color: theme.muted),
              _delete,
              flat: true,
            ),
          ],
        ),
      ],
    );
  }
}
