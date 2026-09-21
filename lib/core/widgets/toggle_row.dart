// ============================================================
// TOGGLE ROW — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10 * widthScale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 20 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              activeThumbColor: AppColor.white,
              activeTrackColor: AppColor.orange,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}