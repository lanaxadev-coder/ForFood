import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_event.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_state.dart';

class RestaurantListBloc
    extends Bloc<RestaurantListEvent, RestaurantListState> {
  final FirestoreProvider _firestoreProvider;

  RestaurantListBloc(FirestoreProvider firestoreProvider)
      : _firestoreProvider = firestoreProvider,
        super(const RestaurantListState()) {
    on<RestaurantListEventFetchRecommendations>(_onFetchRecommendations);
    on<RestaurantListEventFetchHighDemands>(_onFetchHighDemands);
  }

  Future<void> _onFetchRecommendations(
    RestaurantListEventFetchRecommendations event,
    Emitter<RestaurantListState> emit,
  ) async {
    emit(state.copyWith(isLoadingRecommendations: true, clearError: true));

    try {
      final restaurants =
          await _firestoreProvider.getAllRestaurants(limit: 20);

      final items = <RestaurantListItem>[];
      for (final restaurant in restaurants) {
        final distanceKm = _calculateDistance(
          userLatitude: event.userLatitude,
          userLongitude: event.userLongitude,
          restaurantLatitude: restaurant.latitude,
          restaurantLongitude: restaurant.longitude,
        );
        items.add(RestaurantListItem(restaurant: restaurant, distanceKm: distanceKm));
      }

      items.sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        final ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) return ratingComparison;
        return a.distanceKm.compareTo(b.distanceKm);
      });

      emit(state.copyWith(
        recommendations: items,
        isLoadingRecommendations: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingRecommendations: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onFetchHighDemands(
    RestaurantListEventFetchHighDemands event,
    Emitter<RestaurantListState> emit,
  ) async {
    emit(state.copyWith(isLoadingHighDemands: true, clearError: true));

    try {
      final restaurants =
          await _firestoreProvider.getAllRestaurants(limit: 20);

      final popularDishes = <PopularDish>[];

      for (final restaurant in restaurants) {
        final menuItems =
            await _firestoreProvider.getMenuItemsByRestaurantId(restaurant.id);

        final orderedDishes = menuItems.where((item) => item.orderCount > 0);

        for (final dish in orderedDishes) {
          final distanceKm = _calculateDistance(
            userLatitude: event.userLatitude,
            userLongitude: event.userLongitude,
            restaurantLatitude: restaurant.latitude,
            restaurantLongitude: restaurant.longitude,
          );

          popularDishes.add(
            PopularDish(
              restaurant: restaurant,
              menuItem: dish,
              distanceKm: distanceKm,
            ),
          );
        }
      }

      // Sort globally: highest order count → highest rating → nearest
      popularDishes.sort((a, b) {
        final orderComparison = b.menuItem.orderCount.compareTo(a.menuItem.orderCount);
        if (orderComparison != 0) return orderComparison;

        final ratingComparison = b.restaurant.rating.compareTo(a.restaurant.rating);
        if (ratingComparison != 0) return ratingComparison;

        return a.distanceKm.compareTo(b.distanceKm);
      });

      // Optional: limit to top 10 dishes
      final topDishes = popularDishes.take(10).toList();

      emit(state.copyWith(
        highDemands: topDishes,
        isLoadingHighDemands: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingHighDemands: false,
        error: e.toString(),
      ));
    }
  }

  double _calculateDistance({
    double? userLatitude,
    double? userLongitude,
    required double restaurantLatitude,
    required double restaurantLongitude,
  }) {
    if (userLatitude == null || userLongitude == null) return 0;
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(userLatitude);
    final lat2 = _toRadians(restaurantLatitude);
    final deltaLat = _toRadians(restaurantLatitude - userLatitude);
    final deltaLng = _toRadians(restaurantLongitude - userLongitude);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}