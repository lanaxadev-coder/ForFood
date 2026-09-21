import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class DottedDivider extends StatelessWidget {
  final Color color;
  final double dotWidth;
  final double dotHeight;

  const DottedDivider({
    super.key,
    this.color = AppColor.orange,
    this.dotWidth = 2,
    this.dotHeight = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final dotCount = (maxWidth / (dotWidth * 2)).floor();
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,  // ← ADD THIS LINE!
          children: List.generate(dotCount, (index) {
            return Container(
              width: dotWidth,
              height: dotHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(dotHeight),
              ),
            );
          }),
        );
      },
    );
  }
}