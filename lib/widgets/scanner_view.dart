import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';

/// A live QR scanner (mobile_scanner) wrapped in the design's square viewfinder
/// with accent corner brackets and an animated scan line. Falls back to a
/// message when the camera is unavailable (e.g. desktop/web without a camera).
class ScannerView extends StatefulWidget {
  final AppTheme theme;
  final void Function(String rawValue) onCode;

  const ScannerView({super.key, required this.theme, required this.onCode});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with SingleTickerProviderStateMixin {
  late final AnimationController _scan =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat(reverse: true);
  bool _handled = false;

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _handled = true;
        widget.onCode(v);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              fit: BoxFit.cover,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _fallback(theme, error),
            ),
            Container(color: Colors.black.withValues(alpha: 0.30)),
            LayoutBuilder(builder: (context, c) {
              final inset = c.maxWidth * 0.18;
              final frame = c.maxWidth - inset * 2;
              return Center(
                child: SizedBox(
                  width: frame,
                  height: frame,
                  child: Stack(
                    children: [
                      ..._corners(theme),
                      AnimatedBuilder(
                        animation: _scan,
                        builder: (context, _) {
                          final y = Curves.easeInOut.transform(_scan.value) * (frame - 4);
                          return Positioned(
                            left: 6,
                            right: 6,
                            top: y,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  theme.accent,
                                  Colors.transparent,
                                ]),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(color: theme.accent, blurRadius: 14, spreadRadius: 2),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _fallback(AppTheme theme, MobileScannerException error) {
    return Container(
      color: const Color(0xFF0C0E13),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon('qr', size: 40, color: theme.dim),
          const SizedBox(height: 12),
          Text(
            'Camera unavailable on this device.\nUse "Enter manually" instead.',
            textAlign: TextAlign.center,
            style: theme.ui(size: 13.5, weight: FontWeight.w400, color: theme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners(AppTheme theme) {
    BorderSide side() => BorderSide(color: theme.accent, width: 3);
    const len = 34.0;
    Widget corner({required bool top, required bool left}) {
      return Positioned(
        top: top ? -2 : null,
        bottom: top ? null : -2,
        left: left ? -2 : null,
        right: left ? null : -2,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(
              top: top ? side() : BorderSide.none,
              bottom: top ? BorderSide.none : side(),
              left: left ? side() : BorderSide.none,
              right: left ? BorderSide.none : side(),
            ),
            borderRadius: BorderRadius.only(
              topLeft: top && left ? const Radius.circular(16) : Radius.zero,
              topRight: top && !left ? const Radius.circular(16) : Radius.zero,
              bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
              bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
            ),
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }
}
