// ============================================================
// TAB ROUTE — instant navigation for bottom nav taps
// No animation. No fade. Just swap the screen.
// ============================================================

import 'package:flutter/material.dart';

Route<T> tabRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
  );
}