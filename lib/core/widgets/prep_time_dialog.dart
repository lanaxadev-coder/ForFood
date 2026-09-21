// ============================================================
// PREP TIME DIALOG
// ============================================================
// Shows estimated preparation time options.
// Restaurant selects time when accepting order.
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

/// Shows prep time selection dialog.
/// Returns selected minutes (or null if cancelled).
Future<int?> showPrepTimeDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColor.nearWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Estimated preparation time?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColor.textDark,
          fontSize: 20,
          fontFamily: 'League Spartan',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _timeOption(context, 10),
              _timeOption(context, 15),
              _timeOption(context, 20),
              _timeOption(context, 30),
              _timeOption(context, 45),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _timeOption(BuildContext context, int minutes) {
  return GestureDetector(
    onTap: () => Navigator.pop(context, minutes),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.orange,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$minutes min',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'League Spartan',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}