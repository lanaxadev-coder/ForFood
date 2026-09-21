// ============================================================
// RESTAURANT LIST STATE — COMBINED WITH POPULAR DISHES
// ============================================================

import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/models/menu_item_model.dart';

/// Represents a restaurant with its top menu item and distance.
class RestaurantListItem {
  final RestaurantModel restaurant;
  final MenuItemModel? topItem;
  final double distanceKm;

  const RestaurantListItem({
    required this.restaurant,
    this.topItem,
    this.distanceKm = 0,
  });

  bool get isFeatured => restaurant.isFeatured;
  double get rating => restaurant.rating;
  int get topOrderCount => topItem?.orderCount ?? 0;
}

/// Represents a single popular dish across all restaurants.
class PopularDish {
  final RestaurantModel restaurant;
  final MenuItemModel menuItem;
  final double distanceKm;

  const PopularDish({
    required this.restaurant,
    required this.menuItem,
    required this.distanceKm,
  });
}

class RestaurantListState {
  final List<RestaurantListItem> recommendations;
  final List<PopularDish> highDemands; // ✅ Flat list of popular dishes
  final bool isLoadingRecommendations;
  final bool isLoadingHighDemands;
  final String? error;

  const RestaurantListState({
    this.recommendations = const [],
    this.highDemands = const [],
    this.isLoadingRecommendations = false,
    this.isLoadingHighDemands = false,
    this.error,
  });

  RestaurantListState copyWith({
    List<RestaurantListItem>? recommendations,
    List<PopularDish>? highDemands,
    bool? isLoadingRecommendations,
    bool? isLoadingHighDemands,
    String? error,
    bool clearError = false,
  }) {
    return RestaurantListState(
      recommendations: recommendations ?? this.recommendations,
      highDemands: highDemands ?? this.highDemands,
      isLoadingRecommendations:
          isLoadingRecommendations ?? this.isLoadingRecommendations,
      isLoadingHighDemands:
          isLoadingHighDemands ?? this.isLoadingHighDemands,
      error: clearError ? null : error ?? this.error,
    );
  }
}