// ============================================================
// ORDER LIST CARD — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class OrderListCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String date;
  final String itemsCount;
  final String price;
  final String statusNote;
  final String actionLabel;
  final VoidCallback onAction;
  final bool showSecondaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onTap;                     // 👈 NEW

  const OrderListCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.date,
    required this.itemsCount,
    required this.price,
    required this.statusNote,
    required this.actionLabel,
    this.showSecondaryAction = false,
    required this.onAction,
    this.onSecondaryAction,
      this.onTap,                                  // 👈 NEW

  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
  onTap: onTap,
  behavior: HitTestBehavior.opaque,
  child: Padding(
    padding: EdgeInsets.only(bottom: 20 * widthScale),
    child: Column(
      children: [
          Container(
            height: 0.5,
            color: AppColor.orange,
            width: double.infinity,
          ),
          SizedBox(height: 10 * widthScale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             NetworkImageWithShimmer(
  imageUrl: imageUrl,
  width: 72 * widthScale,
  height: 108 * widthScale,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(19.12),
), 
              SizedBox(width: 12 * widthScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 20 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          price,
                          style: TextStyle(
                            color: AppColor.red,
                            fontSize: 20 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 14 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          itemsCount,
                          style: TextStyle(
                            color: AppColor.textDark,
                            fontSize: 14 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * widthScale),
                    Text(
                      statusNote,
                      style: TextStyle(
                        color: AppColor.red,
                        fontSize: 14 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 8 * widthScale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: onAction,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5 * widthScale,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.orange,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              actionLabel,
                              style: TextStyle(
                                color: AppColor.white,
                                fontSize: 13 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (showSecondaryAction)
                          GestureDetector(
                            onTap: onSecondaryAction,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6 * widthScale,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDECF),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Order Again',
                                style: TextStyle(
                                  color: AppColor.red,
                                  fontSize: 13 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w400,
                                ),
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
        ],
      ),
    ),); 
  }
}