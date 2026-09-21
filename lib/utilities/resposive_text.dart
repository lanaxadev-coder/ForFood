// lib/core/widgets/responsive_text.dart

import 'package:flutter/material.dart';
import 'package:forfood/utilities/responsive_helper.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;

  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final String? fontFamily;

  final double? letterSpacing;
  final double? height;

  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.fontSize,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.fontFamily,
    this.letterSpacing,
    this.height,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: ResponsiveHelper.fs(context, fontSize),
        fontWeight: fontWeight,
        fontFamily: fontFamily,
        letterSpacing: letterSpacing != null
            ? ResponsiveHelper.s(context, letterSpacing!)
            : null,
        height: height,
      ),
    );
  }
}