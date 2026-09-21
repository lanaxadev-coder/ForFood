// ============================================================
// SMOOTH PAGE TRANSITIONS
// ============================================================

import 'package:flutter/material.dart';

/// Fade + Slide up transition (subtle and smooth)
Route<T> fadeSlideRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

/// Fade only transition (for drawer items)
Route<T> fadeRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}