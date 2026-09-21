// ============================================================
// HIGH DEMAND CARD — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class HighDemandCard extends StatelessWidget {
  final String imageUrl;
  final String rating;
  final String price;
  final String restaurantName;
  final String dishName;
  final double distanceKm;
  final int orderCount;
  final bool isDelivery;
  final VoidCallback onTap;

  const HighDemandCard({
    super.key,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.restaurantName,
    required this.dishName,
    required this.distanceKm,
    required this.orderCount,
    required this.isDelivery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 159 * widthScale,
        height: 140 * widthScale,
        margin: EdgeInsets.only(right: 10 * widthScale),
        child: Stack(
          children: [
            // Image
            Positioned(
              left: 0,
              top: 0,
              child: NetworkImageWithShimmer(
  imageUrl: imageUrl,
  width: 159 * widthScale,
  height: 140 * widthScale,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(20),
)
            ),

            // Rating badge
            Positioned(
              top: 10 * widthScale,
              left: 14 * widthScale,
              child: Container(
                width: 34 * widthScale,
                height: 14 * widthScale,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rating,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF391713),
                        fontSize: 11 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(width: 2.2 * widthScale),
                    SvgPicture.asset(
                      'assets/icons/star.svg',
                      width: 8.5 * widthScale,
                      height: 8.5 * widthScale,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),

            // Price tag
            Positioned(
              top: 107 * widthScale,
              left: 120 * widthScale,
              child: Container(
                width: 38 * widthScale,
                height: 16 * widthScale,
                clipBehavior: Clip.antiAlias,
                decoration: const ShapeDecoration(
                  color: Color(0xFFE95322),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    price,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}