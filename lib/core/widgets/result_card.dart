// ============================================================
// RESULT CARD — PRODUCTION READY (RESPONSIVE)
// Bottom row: [see in map]  ←→  [Add to Cart]
// Mode (Delivery/Dine-in) now sits in the info row.
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class ResultCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String dishPreview;
  final String distance;
  final String rating;
  final String price;
  final String mode;
  final VoidCallback onTap;
  final VoidCallback onViewAll;
  final VoidCallback onSeeInMap;
  final VoidCallback onAddToCart;      // ✅ NEW

  const ResultCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.dishPreview,
    required this.distance,
    required this.rating,
    required this.price,
    required this.mode,
    required this.onTap,
    required this.onViewAll,
    required this.onSeeInMap,
    required this.onAddToCart,          // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14 * widthScale),
        decoration: BoxDecoration(
          color: AppColor.orange,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NetworkImageWithShimmer(
                imageUrl: imageUrl,
                width: 90 * widthScale,
                height: 110 * widthScale,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(width: 12 * widthScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Name + View All ───
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 16 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onViewAll,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: AppColor.yellow,
                                fontSize: 10 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColor.yellow,
                              size: 14 * widthScale,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * widthScale),

                  // ─── Dish preview ───
                  Text(
                    dishPreview,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 12 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 4 * widthScale),

                  // ─── Distance • rating • price ───
                  Row(
                    children: [
                      Text(
                        distance,
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 11 * widthScale,
                          fontFamily: 'League Spartan',
                        ),
                      ),
                      SizedBox(width: 6 * widthScale),
                      Icon(
                        Icons.star,
                        color: const Color(0xFFF4BA1A),
                        size: 14 * widthScale,
                      ),
                      SizedBox(width: 2 * widthScale),
                      Text(
                        rating,
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 11 * widthScale,
                          fontFamily: 'League Spartan',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: TextStyle(
                          color: AppColor.yellow,
                          fontSize: 20 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6 * widthScale),

                  // ─── Mode badge + see in map + Add to Cart ───
                  Row(
                    children: [
                      // Mode chip (Delivery / Dine-in) — kept, just shifted left
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * widthScale,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7F8A9),
                          borderRadius: BorderRadius.circular(20.5),
                        ),
                        child: Text(
                          mode,
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 10 * widthScale,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * widthScale),

                      // see in map (secondary action)
                      GestureDetector(
                        onTap: onSeeInMap,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * widthScale,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.yellow,
                            border: Border.all(color: const Color(0xFFB7F8A9)),
                            borderRadius: BorderRadius.circular(20.5),
                          ),
                          child: Text(
                            'see in map',
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 10 * widthScale,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ✅ Add to Cart — primary action, right-aligned
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * widthScale,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                size: 13 * widthScale,
                                color: AppColor.orange,
                              ),
                              SizedBox(width: 4 * widthScale),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: AppColor.orange,
                                  fontSize: 11 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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