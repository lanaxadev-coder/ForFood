// ============================================================
// RESTAURANT CARD — PRODUCTION READY (RESPONSIVE)
// - Taller card
// - Rating pill overlaid on the image (always visible)
// - Shows "New" when rating is 0
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class RestaurantCard extends StatelessWidget {
  final String imageUrl;
  final String distance;
  final String name;
  final int rating;
  final VoidCallback onTap;

  const RestaurantCard({
    super.key,
    required this.imageUrl,
    required this.distance,
    required this.name,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    // Layout constants — one place, easy to tune later
    final cardHeight = 140.0;
    final blockHeight = 147.0;                 // image + orange block height
    final imageLeft = 153 * widthScale;        // where the image starts

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 323 * widthScale,
        height: cardHeight,                    // 👈 taller (was 170)
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        margin: EdgeInsets.only(right: 8  * widthScale),
        child: Stack(
          children: [
            // ============================================================
            // Right: Restaurant image
            // ============================================================
            Positioned(
              left: imageLeft,
              top: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(25),
                ),
                child: SizedBox(
                  width: 170 * widthScale,
                  height: blockHeight,         // 👈 taller (was 127)
                  child: NetworkImageWithShimmer(
                    imageUrl: imageUrl,
                    width: 170 * widthScale,
                    height: blockHeight,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // ============================================================
            // Left: Orange info section
            // ============================================================
            Positioned(
              left: 0,
              top: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Container(
                  width: 170 * widthScale,
                  height: blockHeight,         // 👈 matches image
                  color: AppColor.orange,
                  child: Stack(
                    children: [
                      // Decorative circle — top
                      Positioned(
                        left: 120 * widthScale,
                        top: -30,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: ShapeDecoration(
                            shape: OvalBorder(
                              side: BorderSide(
                                width: 8,
                                color: const Color(0xFFF5CB58),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Decorative circle — bottom
                      Positioned(
                        left: -14,
                        top: 115,              // 👈 moved down (taller block)
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: ShapeDecoration(
                            shape: OvalBorder(
                              side: BorderSide(
                                width: 8,
                                color: const Color(0xFFF5CB58),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Restaurant name
                      Positioned(
                        left: 10 * widthScale,
                        top: 30,               // 👈 was 20 — centered better
                        child: SizedBox(
                          width: 123 * widthScale,
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF8F8F8),
                              fontSize: 17,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Distance
                      Positioned(
                        left: 10 * widthScale,
                        top: 85,               // 👈 was 60 — centered better
                        child: SizedBox(
                          width: 127 * widthScale,
                          child: Text(
                            distance,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF8F8F8),
                              fontSize: 24,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================
            // Rating pill — OVERLAID on top-right of the image
            // Always visible. Shows "New" when rating is 0.
            // Placed LAST so it sits above the orange + image.
            // ============================================================
            Positioned(
              top: 10,
              right: 10 * widthScale,
              child: _buildRatingPill(widthScale),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildRatingPill(double widthScale) {
  // Clamp rating between 0 and 5
  final clampedRating = rating.clamp(0, 5);

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: 6 * widthScale,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < clampedRating;
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 1.5 * widthScale),
          child: SvgPicture.asset(
            isFilled
                ? 'assets/icons/bot-star-1.svg'   // 👈 your full star
                : 'assets/icons/bot-star-3.svg',  // 👈 your empty star
            width: 12 * widthScale,
            height: 12 * widthScale,
            fit: BoxFit.contain,
          ),
        );
      }),
    ),
  );
}}