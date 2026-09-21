import 'package:flutter/material.dart';
import 'responsive_helper.dart';

class ResponsiveContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Decoration? decoration;
  final BorderRadius? borderRadius;
  final AlignmentGeometry? alignment;
  final Widget? child;

  const ResponsiveContainer({
    super.key,
    this.width,
    this.height,
    this.color,
    this.decoration,
    this.borderRadius,
    this.alignment,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Decoration? finalDecoration = decoration;

    // If a color was supplied separately, merge it into the decoration.
    if (color != null || borderRadius != null) {
      finalDecoration = BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        image: decoration is BoxDecoration
            ? (decoration as BoxDecoration).image
            : null,
        border: decoration is BoxDecoration
            ? (decoration as BoxDecoration).border
            : null,
        boxShadow: decoration is BoxDecoration
            ? (decoration as BoxDecoration).boxShadow
            : null,
        gradient: decoration is BoxDecoration
            ? (decoration as BoxDecoration).gradient
            : null,
      );
    }

    return Container(
      width: width != null
          ? ResponsiveHelper.w(context, width!)
          : null,
      height: height != null
          ? ResponsiveHelper.h(context, height!)
          : null,
      alignment: alignment,
      decoration: finalDecoration,
      child: child,
    );
  }
}