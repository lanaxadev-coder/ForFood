// ============================================================
// DRAWER HELPERS — PRODUCTION READY (FIXED NAVIGATION)
// ============================================================

import 'package:flutter/material.dart';

import 'package:forfood/core/widgets/restaurant_app_drawer.dart';
import 'package:forfood/core/widgets/show_log_out_dialog.dart';
import 'package:forfood/core/widgets/user_app_drawer.dart';
import 'package:forfood/utilities/page_transition.dart';

import 'package:forfood/view/restaurant/profile.dart';
import 'package:forfood/view/restaurant/review_view.dart';
import 'package:forfood/view/restaurant/subscription_view.dart';
import 'package:forfood/view/user/delivery_adress.dart';
import 'package:forfood/view/user/help_faq_contact_us.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:forfood/view/user/profile.dart';
import 'package:forfood/view/user/setting.dart';

/// Creates a UserAppDrawer with all navigation wired.
UserAppDrawer buildUserDrawer({
  required String name,
  required String email,
  String? profileImageUrl,
}) {
  return UserAppDrawer(
    name: name,
    email: email,
    profileImageUrl: profileImageUrl,
    onMyOrders: (context) => _navigateTo(context, const MyOrdersView()),
    onMyProfile: (context) => _navigateTo(context, const UserProfileView()),
    onDeliveryAddress: (context) =>
        _navigateTo(context, const DeliveryAddressView()),
    onContactUs: (context) => _navigateTo(context, const SupportView()),
    onHelpFAQs: (context) => _navigateTo(context, const SupportView()),
    onSettings: (context) => _navigateTo(context, const SettingsView()),
    onLogout: (context) => showLogoutDialog(context),
  );
}

/// Creates a RestaurantAppDrawer with all navigation wired.
RestaurantAppDrawer buildRestaurantDrawer({
  required String name,
  required String email,
  String? profileImageUrl,
}) {
  return RestaurantAppDrawer(
    name: name,
    email: email,
    profileImageUrl: profileImageUrl,
    onMyProfile: (context) =>
        _navigateTo(context, const ProfileViewRestaurant()),
    onSubscription: (context) =>
        _navigateTo(context, const SubscriptionView()),
    onReviews: (context) => _navigateTo(context, const ReviewsView()),  // 👈 NEW
    onContactUs: (context) => _navigateTo(context, const SupportView()),
    onHelpFAQs: (context) => _navigateTo(context, const SupportView()),
    onSettings: (context) => _navigateTo(context, const SettingsView()),
    onLogout: (context) => showLogoutDialog(context),
  );
}

/// ✅ FIXED: Close drawer, then navigate using fresh context
void _navigateTo(BuildContext context, Widget screen) {
  // Close drawer first
  Navigator.of(context).pop();

  // Use root navigator context after drawer is closed
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.of(context).push(
         fadeSlideRoute( screen),
      );
    }
  });
}