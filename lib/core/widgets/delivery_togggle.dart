// ============================================================
// DELIVERY TOGGLE — controlled widget (parent owns the state)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/utilities/haptic_feedback.dart';

class DeliveryToggle extends StatelessWidget {
  /// Current value — the parent controls this.
  final bool value;

  /// Called when user taps. Null disables the toggle.
  final ValueChanged<bool>? onChanged;

  const DeliveryToggle({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Delivery',
          style: TextStyle(
            color: AppColor.orange,
            fontSize: 12 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Transform.scale(
          scale: 0.55,
          child: Switch(
            value: value,
            activeThumbColor: AppColor.white,
            activeTrackColor: AppColor.orange,
            inactiveThumbColor: AppColor.white,
            inactiveTrackColor: AppColor.orange.withOpacity(0.3),
            onChanged: onChanged == null
                ? null
                : (newValue) {
                    HapticFeedbackUtil.light();
                    onChanged!(newValue);
                  },
          ),
        ),
      ],
    );
  }
}