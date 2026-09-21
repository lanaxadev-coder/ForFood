// ============================================================
// MENU LIST ITEM — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class MenuListItem extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String price;
  final VoidCallback? onTap;

  const MenuListItem({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 107 * widthScale,
        padding: EdgeInsets.all(11 * widthScale),
        decoration: BoxDecoration(
          color: AppColor.orange,
          borderRadius: BorderRadius.circular(38),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 105 * widthScale,
              height: 81 * widthScale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child:NetworkImageWithShimmer(
  imageUrl: imageUrl,
  width: 105 * widthScale,
  height: 81 * widthScale,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(17),
)
              ),
            ),
            SizedBox(width: 16 * widthScale),

            // Name and price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.black,
                      fontSize: 22 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8 * widthScale),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10 * widthScale),
                      child: Text(
                        price,
                        style: TextStyle(
                          color: AppColor.yellow,
                          fontSize: 28 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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