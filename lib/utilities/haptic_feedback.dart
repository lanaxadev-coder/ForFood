// ============================================================
// HAPTIC FEEDBACK UTILITY
// ============================================================

import 'package:flutter/services.dart';

class HapticFeedbackUtil {
  /// Light impact for subtle taps (nav, selection)
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for confirmations (add to cart, toggle)
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for important actions (order accept/reject, delete)
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click for list items
  static void selection() {
    HapticFeedback.selectionClick();
  }
}