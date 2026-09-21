// ============================================================
// HIGH DEMAND LIST CARD — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class HighDemandListCard extends StatelessWidget {
  final String restaurantName;
  final String dishName;
  final String imageUrl;
  final double distanceKm;
  final double rating;
  final double price;
  final int orderCount;
  final bool isDelivery;
  final VoidCallback onTap;
  final VoidCallback onSeeInMap;
  final VoidCallback onViewAll;

  const HighDemandListCard({
    super.key,
    required this.restaurantName,
    required this.dishName,
    required this.imageUrl,
    required this.distanceKm,
    required this.rating,
    required this.price,
    required this.orderCount,
    required this.isDelivery,
    required this.onTap,
    required this.onSeeInMap,
    required this.onViewAll,
  });

  String get _formattedOrderCount {
    if (orderCount >= 1000) {
      return '+${(orderCount / 1000).toStringAsFixed(orderCount % 1000 == 0 ? 0 : 1)}k';
    }
    return '+$orderCount';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * widthScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10 * widthScale),
                  child: Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'League Spartan',
                      fontSize: 20 * widthScale,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF391713),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All  ',
                        style: TextStyle(
                          fontFamily: 'League Spartan',
                          fontSize: 13 * widthScale,
                          fontWeight: FontWeight.w600,
                          color: AppColor.orange,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/NexticonArrow.svg',
                        width: 13 * widthScale,
                        height: 13 * widthScale,
                        fit: BoxFit.contain,
                        color: AppColor.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10 * widthScale),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:NetworkImageWithShimmer(
  imageUrl: imageUrl,
  width: 116 * widthScale,
  height: 116 * widthScale,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(24),
)
                ),
                SizedBox(width: 14 * widthScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'League Spartan',
                          fontSize: 15 * widthScale,
                          color: Color(0xFF391713),
                        ),
                      ),
                      SizedBox(height: 6 * widthScale),
                      Row(
                        children: [
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontFamily: 'League Spartan',
                              fontSize: 13 * widthScale,
                              color: Color(0xFF391713),
                            ),
                          ),
                          SizedBox(width: 8 * widthScale),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13 * widthScale,
                              color: AppColor.textDark,
                            ),
                          ),
                          SizedBox(width: 5 * widthScale),
                          SvgPicture.asset(
                            'assets/icons/bot-star.svg',
                            width: 20 * widthScale,
                            height: 20 * widthScale,
                            fit: BoxFit.contain,
                            color: AppColor.yellow,
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * widthScale),
                      Row(
                        children: [
                          if (isDelivery)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widthScale,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB7F8A9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Delivery',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11 * widthScale,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF391713),
                                ),
                              ),
                            ),
                          SizedBox(width: 8 * widthScale),
                          GestureDetector(
                            onTap: onSeeInMap,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widthScale,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5CB58),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFB7F8A9)),
                              ),
                              child: Text(
                                'see in map',
                                style: TextStyle(
                                  fontSize: 11 * widthScale,
                                  color: Color(0xFF391713),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20 * widthScale),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 30 * widthScale),
                    Text(
                      '${price.toStringAsFixed(0)} \$',
                      style: TextStyle(
                        fontFamily: 'League Spartan',
                        fontSize: 30 * widthScale,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE95322),
                      ),
                    ),
                    Text(
                      _formattedOrderCount,
                      style: TextStyle(
                        fontFamily: 'League Spartan',
                        fontSize: 26 * widthScale,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE95322),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}