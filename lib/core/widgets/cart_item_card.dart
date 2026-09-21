import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';

class CartItemCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double price;
  final int quantity;
  final String date;
  final String time;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CartItemCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.quantity,
    required this.date,
    required this.time,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: NetworkImageWithShimmer(
            imageUrl: imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
             borderRadius: BorderRadius.circular(17),

          
            ),
          ),
      
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.45,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFF8F8F8),
                  fontSize: 14,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // ✅ Minus button - just IconData
                _StepperButton(
                  icon: Icons.remove,  // ← IconData
                  onTap: onDecrement,
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF8F8F8),
                      fontSize: 13,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                // ✅ Plus button - just IconData
                _StepperButton(
                  icon: Icons.add,  // ← IconData
                  onTap: onIncrement,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;  // ← IconData, not Icon widget!
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
  width: 44,
  height: 44,
  // Keep visual smaller with padding
  padding: const EdgeInsets.all(14), // Icon stays ~16px visible

        decoration: BoxDecoration(
          color: AppColor.nearWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,  // ← This is IconData, used correctly here
          size: 10,
          color: AppColor.orange,  // ← Changed to orange for visibility
        ),
      ),
    );
  }
}