import 'package:flutter/material.dart';

/// A slide + fade page transition matching the prototype's screen push
/// (~320ms, cubic-bezier(0.32, 0.72, 0, 1)). Forward slides in from the
/// right; popping reverses it.
Route<T> appRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.32, 0.72, 0, 1),
        reverseCurve: const Cubic(0.32, 0.72, 0, 1),
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.18, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
