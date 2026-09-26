// ============================================================
// RECOMMENDATION LIST CARD — RATING PARAM FIXED
// ============================================================
// Card for restaurant recommendations list.
// Uses actual rating from param instead of hardcoded 4.
// ============================================================
// ============================================================
// RECOMMENDATION LIST CARD — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/star_rating.dart';

class RecommendationListCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String distance;
  final String rating;
  final VoidCallback onTap;
  final VoidCallback onSeeMore;

  const RecommendationListCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.distance,
    required this.rating,
    required this.onTap,
    required this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    final ratingValue = int.tryParse(rating.split('.').first) ?? 4;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 14 * widthScale,
          horizontal: 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 116 * widthScale,
                height: 132 * widthScale,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 116 * widthScale,
                  height: 132 * widthScale,
                  color: const Color(0xFFFFDECF),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 116 * widthScale,
                  height: 132 * widthScale,
                  color: const Color(0xFFFF9E74),
                  child: const Icon(Icons.restaurant, color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 16 * widthScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "See more" at top right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onSeeMore,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See more ',
                              style: TextStyle(
                                color: AppColor.orange,
                                fontSize: 12 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/NexticonArrow.svg',
                              width: 13 * widthScale,
                              height: 13 * widthScale,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 18 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6 * widthScale),
                  Text(
                    distance,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 14 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 6 * widthScale),
                  Row(
                    children: [
                      StarRating(rating: ratingValue),
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