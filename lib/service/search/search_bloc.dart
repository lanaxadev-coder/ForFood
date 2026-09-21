// ============================================================
// SEARCH BLOC — WITH DEBUG
// ============================================================

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/menu_item_model.dart';
import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/search/search_event.dart';
import 'package:forfood/service/search/search_state.dart';
import 'package:forfood/utilities/geohach_util.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final FirestoreProvider _firestoreProvider;

  static const int _geohashPrecision = 5;
  static const double _maxSearchRadiusKm = 50.0;

  SearchBloc(FirestoreProvider firestoreProvider)
      : _firestoreProvider = firestoreProvider,
        super(const SearchStateInitial()) {
    on<SearchEventPerformSearch>(_onPerformSearch);
    on<SearchEventClearResults>(_onClearResults);
  }

  Future<void> _onPerformSearch(
    SearchEventPerformSearch event,
    Emitter<SearchState> emit,
  ) async {
    if (state is SearchStateLoading) return;

    // ═══════════════════════════════════════════════════════════
    // DEBUG 1 — INPUTS
    // ═══════════════════════════════════════════════════════════
    debugPrint('🔍 [SEARCH] ═══════ START ═══════');
    debugPrint('🔍 [SEARCH] craving="${event.craving}"');
    debugPrint('🔍 [SEARCH] maxBudget=${event.maxBudget}');
    debugPrint('🔍 [SEARCH] userLat=${event.userLatitude}');
    debugPrint('🔍 [SEARCH] userLng=${event.userLongitude}');

    if (event.userLatitude == 0 && event.userLongitude == 0) {
      debugPrint('❌ [SEARCH] Location is 0,0 — aborting');
      emit(const SearchStateError(
        message: 'Unable to determine your location. '
            'Please enable location services and try again.',
      ));
      return;
    }

    emit(const SearchStateLoading());

    try {
      if (event.maxBudget <= 0) {
        throw const PriceFilterOutOfRangeException();
      }

      // ═══════════════════════════════════════════════════════════
      // DEBUG 2 — GEOHASH
      // ═══════════════════════════════════════════════════════════
      final centerPrefix = GeohashUtil.encode(
        latitude: event.userLatitude,
        longitude: event.userLongitude,
        precision: _geohashPrecision,
      );
      debugPrint('🔍 [SEARCH] centerPrefix="$centerPrefix"');

      final prefixes = GeohashUtil.neighbours(centerPrefix);
      debugPrint('🔍 [SEARCH] prefixes=$prefixes');

      final restaurants = <RestaurantModel>[];
      final seen = <String>{};
      for (final prefix in prefixes) {
        debugPrint('🔍 [SEARCH] querying prefix="$prefix"');
        final results = await _firestoreProvider
            .searchRestaurantsByGeohashPrefix(prefix);
        debugPrint('🔍 [SEARCH]   → got ${results.length} docs');
        for (final r in results) {
          if (seen.add(r.id)) {
            restaurants.add(r);
            debugPrint('🔍 [SEARCH]   + "${r.name}" geohash=${r.geohash} '
                'lat=${r.latitude} lng=${r.longitude}');
          }
        }
      }

      debugPrint('🔍 [SEARCH] Total restaurants: ${restaurants.length}');

      if (restaurants.isEmpty) {
        debugPrint('⚠️ [SEARCH] EMPTY — no restaurants found in any prefix');
        emit(const SearchStateEmpty());
        return;
      }

      // ═══════════════════════════════════════════════════════════
      // DEBUG 3 — PER RESTAURANT FILTER WALK
      // ═══════════════════════════════════════════════════════════
      final searchResults = <SearchResult>[];

      for (final restaurant in restaurants) {
        debugPrint('───');
        debugPrint('🔍 [SEARCH] Checking "${restaurant.name}" '
            '(${restaurant.id})');

        final menuItems = await _firestoreProvider
            .getMenuItemsByRestaurantId(restaurant.id);
        debugPrint('🔍 [SEARCH]   menu items: ${menuItems.length}');

        if (menuItems.isNotEmpty) {
          for (final m in menuItems) {
            debugPrint(
                '🔍 [SEARCH]     "${m.name}" — \$${m.price.toStringAsFixed(2)}');
          }
        }

        final affordableItems = menuItems
            .where((item) => item.price <= event.maxBudget)
            .toList();
        debugPrint(
            '🔍 [SEARCH]   affordable (≤\$${event.maxBudget}): ${affordableItems.length}');

        if (affordableItems.isEmpty) {
          debugPrint('🔍 [SEARCH]   ✗ SKIP — nothing under budget');
          continue;
        }

        affordableItems.sort((a, b) => a.price.compareTo(b.price));
        final matchingItem = _findBestMatchingItem(
          affordableItems,
          event.craving,
        );

        if (matchingItem == null) {
          debugPrint('🔍 [SEARCH]   ✗ SKIP — no matching item');
          continue;
        }
        debugPrint('🔍 [SEARCH]   match="${matchingItem.name}" '
            'price=\$${matchingItem.price.toStringAsFixed(2)}');

        final distanceKm = _calculateDistanceKm(
          userLatitude: event.userLatitude,
          userLongitude: event.userLongitude,
          restaurantLatitude: restaurant.latitude,
          restaurantLongitude: restaurant.longitude,
        );
        debugPrint(
            '🔍 [SEARCH]   distance=${distanceKm.toStringAsFixed(2)} km');

        if (distanceKm > _maxSearchRadiusKm) {
          debugPrint(
              '🔍 [SEARCH]   ✗ SKIP — beyond ${_maxSearchRadiusKm}km');
          continue;
        }

        searchResults.add(SearchResult(
          restaurant: restaurant,
          cheapestItem: matchingItem,
          distanceKm: distanceKm,
          isBestMatch: false,
        ));
        debugPrint('🔍 [SEARCH]   ✅ ADDED');
      }

      debugPrint('🔍 [SEARCH] searchResults: ${searchResults.length}');

      if (searchResults.isEmpty) {
        debugPrint('⚠️ [SEARCH] EMPTY — nothing passed all filters');
        emit(const SearchStateEmpty());
        return;
      }

      // Sort
      searchResults.sort((a, b) {
        final priceComparison =
            a.cheapestItem.price.compareTo(b.cheapestItem.price);
        if (priceComparison != 0) return priceComparison;
        final distanceComparison = a.distanceKm.compareTo(b.distanceKm);
        if (distanceComparison != 0) return distanceComparison;
        return b.restaurant.rating.compareTo(a.restaurant.rating);
      });

      final finalResults = searchResults.asMap().entries.map((entry) {
        return SearchResult(
          restaurant: entry.value.restaurant,
          cheapestItem: entry.value.cheapestItem,
          distanceKm: entry.value.distanceKm,
          isBestMatch: entry.key == 0,
        );
      }).toList();

      debugPrint(
          '🔍 [SEARCH] ═══════ DONE — ${finalResults.length} results ═══════');
      emit(SearchStateLoaded(
        results: finalResults,
        resultCount: finalResults.length,
      ));
    } on PriceFilterOutOfRangeException catch (e) {
      debugPrint('❌ [SEARCH] PriceFilterOutOfRange: ${e.message}');
      emit(SearchStateError(message: e.message));
    } on FirestoreOperationException catch (e) {
      debugPrint('❌ [SEARCH] FirestoreOperation: ${e.message}');
      emit(SearchStateError(message: e.message));
    } on LocationUnavailableException catch (e) {
      debugPrint('❌ [SEARCH] LocationUnavailable: ${e.message}');
      emit(SearchStateError(message: e.message));
    } catch (e, stack) {
      debugPrint('❌ [SEARCH] Unknown error: $e');
      debugPrint('❌ [SEARCH] Stack: $stack');
      emit(SearchStateError(message: 'Search failed: $e'));
    }
  }

  void _onClearResults(
    SearchEventClearResults event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchStateInitial());
  }

  MenuItemModel? _findBestMatchingItem(
    List<MenuItemModel> affordableItems,
    String craving,
  ) {
    if (craving.isEmpty) {
      return affordableItems.first;
    }
    final cravingLower = craving.toLowerCase();
    return affordableItems.firstWhere(
      (item) => item.name.toLowerCase().contains(cravingLower),
      orElse: () => affordableItems.first,
    );
  }

  double _calculateDistanceKm({
    required double userLatitude,
    required double userLongitude,
    required double restaurantLatitude,
    required double restaurantLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    final lat1 = _degreesToRadians(userLatitude);
    final lat2 = _degreesToRadians(restaurantLatitude);
    final deltaLat = _degreesToRadians(restaurantLatitude - userLatitude);
    final deltaLng = _degreesToRadians(restaurantLongitude - userLongitude);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);
}