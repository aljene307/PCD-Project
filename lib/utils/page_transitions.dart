import 'package:flutter/material.dart';

/// Smooth fade + upward slide page transition used throughout the app.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required Widget page, Duration? duration})
    : super(
        transitionDuration: duration ?? const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}

/// Hero-style fade transition used for the loading -> ranks handoff.
class FadeOnlyPageRoute<T> extends PageRouteBuilder<T> {
  FadeOnlyPageRoute({required Widget page, Duration? duration})
    : super(
        transitionDuration: duration ?? const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}
