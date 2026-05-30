import 'package:flutter/material.dart';

/// A deterministic QR-ish matrix rendered from a seed string. Purely
/// decorative — used to preview an account's "share" code in the design.
class FakeQr extends StatelessWidget {
  final String seed;
  final double size;
  final Color fg;
  final Color bg;

  const FakeQr({
    super.key,
    required this.seed,
    this.size = 180,
    this.fg = const Color(0xFF0A0B0E),
    this.bg = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        size: Size.square(size),
        painter: _QrPainter(seed: seed, fg: fg, bg: bg),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String seed;
  final Color fg;
  final Color bg;
  static const int n = 25;

  _QrPainter({required this.seed, required this.fg, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    final bgPaint = Paint()..color = bg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final fgPaint = Paint()..color = fg;

    int h = 2166136261 & 0xFFFFFFFF;
    for (int i = 0; i < seed.length; i++) {
      h ^= seed.codeUnitAt(i);
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    double rnd() {
      h ^= (h << 13) & 0xFFFFFFFF;
      h ^= h >> 17;
      h ^= (h << 5) & 0xFFFFFFFF;
      h &= 0xFFFFFFFF;
      return h / 4294967295;
    }

    bool finder(int r, int c) =>
        (r < 7 && c < 7) || (r < 7 && c >= n - 7) || (r >= n - 7 && c < 7);

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (finder(r, c)) continue;
        if (rnd() > 0.52) {
          final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.25)), fgPaint);
        }
      }
    }

    void drawFinder(int x, int y) {
      final outer = Rect.fromLTWH(x * cell, y * cell, cell * 7, cell * 7);
      canvas.drawRRect(RRect.fromRectAndRadius(outer, Radius.circular(cell)), fgPaint);
      final mid = Rect.fromLTWH((x + 1) * cell, (y + 1) * cell, cell * 5, cell * 5);
      canvas.drawRRect(
          RRect.fromRectAndRadius(mid, Radius.circular(cell * 0.7)), Paint()..color = bg);
      final inner = Rect.fromLTWH((x + 2) * cell, (y + 2) * cell, cell * 3, cell * 3);
      canvas.drawRRect(
          RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.4)), fgPaint);
    }

    drawFinder(0, 0);
    drawFinder(n - 7, 0);
    drawFinder(0, n - 7);
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.seed != seed || old.fg != fg || old.bg != bg;
}
