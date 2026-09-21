// ============================================================
// YOUR USUAL CARD — one-tap reorder of the user's most repeated order
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/utilities/haptic_feedback.dart';

class YourUsualCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onOrderAgain;

  const YourUsualCard({
    super.key,
    required this.order,
    required this.onOrderAgain,
  });

  /// "Margherita ×2" or "Margherita ×2 + 2 more"
  String get _itemSummary {
    if (order.items.isEmpty) return '';
    if (order.items.length == 1) {
      final item = order.items.first;
      return '${item.name} ×${item.quantity}';
    }
    final first = order.items.first;
    final more = order.items.length - 1;
    return '${first.name} ×${first.quantity} + $more more';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    final imageUrl =
        order.items.isNotEmpty ? order.items.first.imageUrl : null;

    return GestureDetector(
      onTap: () {
        HapticFeedbackUtil.medium();
        onOrderAgain();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14 * widthScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20 * widthScale),
          border: Border.all(color: AppColor.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColor.orange.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Dish image
            ClipRRect(
              borderRadius: BorderRadius.circular(14 * widthScale),
              child: NetworkImageWithShimmer(
                imageUrl: imageUrl ?? 'https://placehold.co/80x80',
                width: 72 * widthScale,
                height: 72 * widthScale,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(14 * widthScale),
              ),
            ),
            SizedBox(width: 12 * widthScale),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    order.restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 15 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3 * widthScale),
                  Text(
                    _itemSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.gray,
                      fontSize: 12 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8 * widthScale),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColor.orange,
                      fontSize: 16 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Order Again button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * widthScale,
                vertical: 9 * widthScale,
              ),
              decoration: BoxDecoration(
                color: AppColor.orange,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4 * widthScale),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 14 * widthScale,
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