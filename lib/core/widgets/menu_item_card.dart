// ============================================================
// MENU ITEM CARD — PRODUCTION READY (RESPONSIVE + TAPPABLE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class MenuItemCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String price;
  final VoidCallback? onTap;  // ✅ ADDED

  const MenuItemCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    this.onTap,  // ✅ ADDED
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 148 * widthScale,
        width: 122 * widthScale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38),
          color: AppColor.orange,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 11 * widthScale,
                left: 11 * widthScale,
                right: 11 * widthScale,
              ),
              child: Container(
                width: 97 * widthScale,
                height: 75 * widthScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child:NetworkImageWithShimmer(
  imageUrl: imageUrl,
  width: 97 * widthScale,
  height: 75 * widthScale,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(17),
)
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColor.textDark,
                        fontSize: 12,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              price,
              style: const TextStyle(
                color: AppColor.yellow,
                fontSize: 14,
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