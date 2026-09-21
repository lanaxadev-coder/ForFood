// ============================================================
// STAT CARD — PRODUCTION READY (RESPONSIVE + TAPPABLE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forfood/core/theme/app_color.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;  // ✅ ADDED

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.onTap,  // ✅ ADDED
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130 * widthScale,
        height: 90 * widthScale,
        decoration: BoxDecoration(
          color: AppColor.yellow,
          borderRadius: BorderRadius.circular(38.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontSize: 20 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2 * widthScale),
                SvgPicture.asset(
                  'assets/icons/NexticonArrow.svg',
                  color: AppColor.black,
                  height: 14 * widthScale,
                  width: 14 * widthScale,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColor.nearWhite,
                fontSize: 32 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}