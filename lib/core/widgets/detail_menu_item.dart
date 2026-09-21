// ============================================================
// DETAIL MENU ITEM — PRODUCTION READY (RESPONSIVE)
// + Tappable image for fullscreen viewer
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/dotted_divider.dart';

class DetailMenuItem extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String price;
  final bool isSelected;
  final VoidCallback onBookmark;

  /// 👈 NEW — optional. When provided, tapping the thumbnail fires this.
  /// Used by RestaurantDetailView to open the fullscreen viewer.
  final VoidCallback? onImageTap;

  const DetailMenuItem({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.isSelected,
    required this.onBookmark,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10 * widthScale),
      child: Row(
        children: [
          // 👈 Image now tappable when onImageTap is provided
          GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                imageUrl,
                width: 34 * widthScale,
                height: 34 * widthScale,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 34 * widthScale,
                  height: 34 * widthScale,
                  color: const Color(0xFFFFDECF),
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * widthScale),
          Expanded(
            flex: 2,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8 * widthScale),
              child: const DottedDivider(),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 60 * widthScale),
            child: Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 13 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 10 * widthScale),
          GestureDetector(
            onTap: onBookmark,
            child: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColor.orange,
              size: 20 * widthScale,
            ),
          ),
        ],
      ),
    );
  }
}