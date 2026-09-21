// lib/core/widgets/responsive_positioned.dart

import 'package:flutter/material.dart';
import 'package:forfood/utilities/responsive_helper.dart';

class ResponsivePositioned extends StatelessWidget {
  final Widget child;

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  final double? width;
  final double? height;

  const ResponsivePositioned({
    super.key,
    required this.child,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top != null ? ResponsiveHelper.s(context, top!) : null,
      bottom: bottom != null ? ResponsiveHelper.s(context, bottom!) : null,
      left: left != null ? ResponsiveHelper.s(context, left!) : null,
      right: right != null ? ResponsiveHelper.s(context, right!) : null,
      width: width != null ? ResponsiveHelper.w(context, width!) : null,
      height: height != null ? ResponsiveHelper.h(context, height!) : null,
      child: child,
    );
  }
}