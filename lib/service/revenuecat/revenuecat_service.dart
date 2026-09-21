// ============================================================
// REVENUECAT SERVICE
// ============================================================
// Single owner of the Purchases SDK.
//
// Initialize once from main.dart when a user logs in.
// All other screens call the static helpers.
//
// Config comes from --dart-define-from-file=.env.json:
//   REVENUECAT_API_KEY=test_xxx / goog_xxx / appl_xxx
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();

  static const String _apiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );

  /// Entitlement identifiers — must match your RevenueCat dashboard.
  static const String premiumEntitlement = 'premium';
  static const String featuredEntitlement = 'featured';

  static bool _isInitialized = false;
  static String? _currentAppUserId;

  /// Call once per authenticated user (from ForFoodApp listener).
  static Future<void> initialize({required String appUserID}) async {
    // No-op if we're already on this user.
    if (_isInitialized && _currentAppUserId == appUserID) return;

    // Different user → logIn so entitlements follow the account.
    if (_isInitialized && _currentAppUserId != appUserID) {
      try {
        await Purchases.logIn(appUserID);
        _currentAppUserId = appUserID;
        debugPrint('✅ RevenueCat switched to $appUserID');
      } catch (e) {
        debugPrint('⚠️ RevenueCat logIn failed: $e');
      }
      return;
    }

    if (_apiKey.isEmpty) {
      debugPrint(
        '⚠️ RevenueCat API key missing. '
        'Build with --dart-define-from-file=.env.json',
      );
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final config = PurchasesConfiguration(_apiKey)..appUserID = appUserID;
    await Purchases.configure(config);

    _isInitialized = true;
    _currentAppUserId = appUserID;
    debugPrint('✅ RevenueCat initialized for $appUserID');
  }

  static Future<void> logOut() async {
    if (!_isInitialized) return;
    await Purchases.logOut();
    _currentAppUserId = null;
  }

  static Future<List<Package>> getPackages() async {
    if (!_isInitialized) return const [];
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? const [];
  }

static Future<CustomerInfo> purchasePackage(Package package) async {
  if (!_isInitialized) {
    throw StateError('RevenueCat not initialized');
  }
  final result = await Purchases.purchase(
    PurchaseParams.package(package),
  );
  return result.customerInfo;
}

  static Future<CustomerInfo> restorePurchases() async {
    if (!_isInitialized) {
      throw StateError('RevenueCat not initialized');
    }
    return Purchases.restorePurchases();
  }

  static Future<bool> isPremiumActive() async {
    if (!_isInitialized) return false;
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(premiumEntitlement);
  }

  static Future<bool> isFeaturedActive() async {
    if (!_isInitialized) return false;
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(featuredEntitlement);
  }

  static bool get isInitialized => _isInitialized;
}