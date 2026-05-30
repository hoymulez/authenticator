import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A scaffold whose body sits on the app's radial background gradient.
class GradientScaffold extends StatelessWidget {
  final AppTheme theme;
  final Widget child;
  final bool safeBottom;

  const GradientScaffold({
    super.key,
    required this.theme,
    required this.child,
    this.safeBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: theme.bgGradient),
        child: SafeArea(
          bottom: safeBottom,
          child: child,
        ),
      ),
    );
  }
}
