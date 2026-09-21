import 'package:flutter/material.dart';

class DotsIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const DotsIndicator({
    super.key,
    required this.activeIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Container(
          width: 20,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: ShapeDecoration(
            color: index == activeIndex
                ? const Color(0xFFE95322) // Active - orange
                : const Color(0xFFF3E9B5), // Inactive - light yellow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}