import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A mock camera viewfinder with corner brackets and an animated scan line.
/// In production this is where `mobile_scanner` renders the live camera feed.
class CameraView extends StatefulWidget {
  final AppTheme theme;
  final bool scanning;

  const CameraView({super.key, required this.theme, this.scanning = true});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radius),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.2,
              colors: [Color(0xFF20242E), Color(0xFF0C0E13)],
              stops: [0, 0.7],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.35))),
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
                        if (widget.scanning)
                          AnimatedBuilder(
                            animation: _c,
                            builder: (context, _) {
                              final curve = Curves.easeInOut.transform(_c.value);
                              return Positioned(
                                left: 6,
                                right: 6,
                                top: curve * (frame - 4),
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
