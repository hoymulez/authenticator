import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/totp.dart';
import '../state/ticker.dart';
import '../theme/app_theme.dart';
import 'brand_tile.dart';

/// Paints a circular progress ring (drains clockwise from 12 o'clock).
class _RingPainter extends CustomPainter {
  final double progress; // 1 -> 0
  final double stroke;
  final Color track;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, r, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * clamp01(progress),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// A ring with the remaining seconds centered inside.
class CountdownRing extends StatelessWidget {
  final AppTheme theme;
  final int period;
  final double size;
  final double stroke;

  const CountdownRing({
    super.key,
    required this.theme,
    this.period = 30,
    this.size = 40,
    this.stroke = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appTick,
      builder: (context, _, _) {
        final rem = Totp.remaining(period);
        final urgent = rem <= 5;
        final col = urgent ? AppTheme.danger : theme.accent;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: Totp.progress(period),
                  stroke: stroke,
                  track: theme.border,
                  color: col,
                ),
              ),
              Text(
                '$rem',
                style: theme.mono(
                  size: size * 0.3,
                  weight: FontWeight.w600,
                  color: urgent ? AppTheme.danger : theme.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A small progress bar + remaining seconds (card "bar" mode).
class CountdownBar extends StatelessWidget {
  final AppTheme theme;
  final int period;

  const CountdownBar({super.key, required this.theme, this.period = 30});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appTick,
      builder: (context, _, _) {
        final rem = Totp.remaining(period);
        final urgent = rem <= 5;
        final col = urgent ? AppTheme.danger : theme.accent;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clamp01(Totp.progress(period)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              child: Text(
                '$rem',
                style: theme.mono(
                    size: 12, weight: FontWeight.w500, color: urgent ? AppTheme.danger : theme.muted),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A progress ring encircling a circular brand tile (card "logo" mode).
class AccountTile extends StatelessWidget {
  final Account account;
  final AppTheme theme;
  final double size;

  const AccountTile({
    super.key,
    required this.account,
    required this.theme,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final ring = size + 13;
    const stroke = 3.0;
    return ValueListenableBuilder<int>(
      valueListenable: appTick,
      builder: (context, _, _) {
        final urgent = Totp.remaining(account.period) <= 5;
        final col = urgent ? AppTheme.danger : theme.accent;
        return SizedBox(
          width: ring,
          height: ring,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(ring),
                painter: _RingPainter(
                  progress: Totp.progress(account.period),
                  stroke: stroke,
                  track: theme.border,
                  color: col,
                ),
              ),
              BrandTile(account: account, size: size, radius: size / 2),
            ],
          ),
        );
      },
    );
  }
}

/// A subtle draining line on the card's bottom edge (card "border" mode).
class PerimeterCountdown extends StatelessWidget {
  final AppTheme theme;
  final int period;
  final double radius;

  const PerimeterCountdown({
    super.key,
    required this.theme,
    this.period = 30,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final double inset = math.min(radius, 18.0) + 2;
    return ValueListenableBuilder<int>(
      valueListenable: appTick,
      builder: (context, _, _) {
        final urgent = Totp.remaining(period) <= 5;
        final col = (urgent ? AppTheme.danger : theme.accent)
            .withValues(alpha: urgent ? 0.95 : 0.6);
        return Positioned(
          left: inset,
          right: inset,
          bottom: 5,
          height: 2.5,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: clamp01(Totp.progress(period)),
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: col,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
