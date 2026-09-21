// ============================================================
// USER STATUS TABS — PRODUCTION READY (RESPONSIVE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

enum OrderTabStatus { active, completed, cancelled }

class UserStatusTabs extends StatelessWidget {
  final OrderTabStatus selected;
  final ValueChanged<OrderTabStatus> onChanged;

  const UserStatusTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tab('Active', OrderTabStatus.active, widthScale),
        SizedBox(width: 5 * widthScale),
        _tab('Completed', OrderTabStatus.completed, widthScale),
        SizedBox(width: 5 * widthScale),
        _tab('Cancelled', OrderTabStatus.cancelled, widthScale),
      ],
    );
  }

  Widget _tab(String label, OrderTabStatus status, double widthScale) {
    final bool isActive = status == selected;
    return GestureDetector(
      onTap: () => onChanged(status),
      child: Container(
        width: 104 * widthScale,
        height: 28 * widthScale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColor.orange : const Color(0xFFFFDECF),
          borderRadius: BorderRadius.circular(38),
          border: isActive
              ? Border.all(color: AppColor.orange, width: 1)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppColor.white : AppColor.orange,
            fontSize: 17 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            height: 1.18,
            letterSpacing: -0.09,
          ),
        ),
      ),
    );
  }
}