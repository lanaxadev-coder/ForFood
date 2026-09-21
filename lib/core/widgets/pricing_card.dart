// ============================================================
// PRICING CARD — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class PricingCard extends StatelessWidget {
  final String planName;
  final String subtitle;
  final String price;
  final String perMonthYear;
  final VoidCallback onTap;

  const PricingCard({
    super.key,
    required this.planName,
    required this.subtitle,
    required this.price,
    required this.perMonthYear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 354 * widthScale,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 15 * widthScale,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          color: AppColor.orange2,
          border: Border.all(
            color: AppColor.red,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left: Plan name and subtitle
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    planName,
                    style: TextStyle(
                      color: AppColor.brown,
                      fontFamily: 'League Spartan',
                      fontSize: 24 * widthScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.trim(),
                    style: TextStyle(
                      color: AppColor.brown,
                      fontFamily: 'League Spartan',
                      fontSize: 14 * widthScale,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            // Right: Price
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: AppColor.orange,
                      fontFamily: 'League Spartan',
                      fontSize: 24 * widthScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    perMonthYear,
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontFamily: 'League Spartan',
                      fontSize: 20 * widthScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}