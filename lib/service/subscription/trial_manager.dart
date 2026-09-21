// ============================================================
// TRIAL MANAGER — HANDLES TRIAL STATUS
// ============================================================

import 'package:forfood/models/restaurant_model.dart';

enum TrialStatus {
  active,
  expiringSoon,  // 7 days or less
  expired,
  premium,       // Paid subscription active
  none,          // No subscription
}

class TrialStatusInfo {
  final TrialStatus status;
  final int daysLeft;
  final String message;

  const TrialStatusInfo({
    required this.status,
    required this.daysLeft,
    required this.message,
  });
}

class TrialManager {
  static TrialStatusInfo getTrialStatus(RestaurantModel? restaurant) {
    if (restaurant == null) {
      return const TrialStatusInfo(
        status: TrialStatus.none,
        daysLeft: 0,
        message: 'Subscribe to unlock premium features',
      );
    }

    final now = DateTime.now();

    // ✅ Premium (paid subscription)
    if (restaurant.subscriptionActive) {
      return const TrialStatusInfo(
        status: TrialStatus.premium,
        daysLeft: 999,
        message: 'Premium active',
      );
    }

    // ✅ Trial active
    final trialEnd = restaurant.subscriptionExpiry;
    if (trialEnd != null && trialEnd.isAfter(now)) {
      final daysLeft = trialEnd.difference(now).inDays;

      if (daysLeft <= 7) {
        return TrialStatusInfo(
          status: TrialStatus.expiringSoon,
          daysLeft: daysLeft,
          message: daysLeft <= 1
              ? '⚠️ Trial ends tomorrow! Upgrade now!'
              : '⚠️ Trial ends in $daysLeft days!',
        );
      }

      return TrialStatusInfo(
        status: TrialStatus.active,
        daysLeft: daysLeft,
        message: '$daysLeft days left in your free trial',
      );
    }

    // ✅ Trial expired
    return const TrialStatusInfo(
      status: TrialStatus.expired,
      daysLeft: 0,
      message: 'Trial ended — Upgrade to continue premium',
    );
  }
}