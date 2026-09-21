import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';

// Single place to show error/success feedback, matching your app's
// look — rounded floating pill, brand fonts/colors, not Flutter's
// default gray SnackBar. Use AppSnackbar.showError(context, message)
// from any bloc listener instead of building a SnackBar inline each time.
class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      iconColor: AppColor.red,
      backgroundColor: AppColor.brown,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: AppColor.orange,
      backgroundColor: AppColor.brown,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColor.white,
                    fontFamily: 'League Spartan',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}