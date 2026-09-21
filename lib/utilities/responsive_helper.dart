// lib/core/utils/responsive_helper.dart

import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Figma design size
  static const double designWidth = 393;
  static const double designHeight = 855;

  /// Screen size
  static Size screenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  /// Uniform scale based on screen width.
  ///
  /// This keeps the Figma design proportional.
  static double scale(BuildContext context) {
    final size = screenSize(context);
    return size.width / designWidth;
  }

  /// Responsive width
  static double w(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Responsive height
  static double h(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Responsive font size
  static double fs(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Responsive spacing
  static double s(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Responsive EdgeInsets
  static EdgeInsets padding(
    BuildContext context, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    final scaleValue = scale(context);

    if (all != null) {
      return EdgeInsets.all(all * scaleValue);
    }

    return EdgeInsets.only(
      top: (top ?? vertical ?? 0) * scaleValue,
      bottom: (bottom ?? vertical ?? 0) * scaleValue,
      left: (left ?? horizontal ?? 0) * scaleValue,
      right: (right ?? horizontal ?? 0) * scaleValue,
    );
  }

  static bool isSmallScreen(BuildContext context) {
    return screenSize(context).width < 375;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = screenSize(context).width;

    return width >= 375 && width < 768;
  }

  static bool isLargeScreen(BuildContext context) {
    return screenSize(context).width >= 768;
  }
}