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
import 'package:forfood/utilities/friendly_error.dart';
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

          // ✅ PARALLEL: fire all 9 geohash queries at once.
      final resultSets = await Future.wait(
        prefixes.map((prefix) {
          debugPrint('🔍 [SEARCH] querying prefix="$prefix"');
          return _firestoreProvider.searchRestaurantsByGeohashPrefix(prefix);
        }),
      );

      final restaurants = <RestaurantModel>[];
      final seen = <String>{};
      for (int i = 0; i < prefixes.length; i++) {
        final results = resultSets[i];
        debugPrint('🔍 [SEARCH]   → prefix "${prefixes[i]}" got ${results.length} docs');
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
           // ✅ PARALLEL: fetch all restaurant menus at once, then filter in memory.
      final menuLists = await Future.wait(
        restaurants.map(
          (r) => _firestoreProvider.getMenuItemsByRestaurantId(r.id),
        ),
      );

      final searchResults = <SearchResult>[];

      for (int i = 0; i < restaurants.length; i++) {
        final restaurant = restaurants[i];
        final menuItems = menuLists[i];

        debugPrint('───');
        debugPrint('🔍 [SEARCH] Checking "${restaurant.name}" '
            '(${restaurant.id})');
        debugPrint('🔍 [SEARCH]   menu items: ${menuItems.length}');

        final affordableItems = menuItems
            .where((item) => item.price <= event.maxBudget)
            .toList();
        debugPrint(
            '🔍 [SEARCH]   affordable (≤\$${event.maxBudget}): ${affordableItems.length}');

        if (affordableItems.isEmpty) continue;

        affordableItems.sort((a, b) => a.price.compareTo(b.price));
        final matchingItem = _findBestMatchingItem(
          affordableItems,
          event.craving,
        );

        if (matchingItem == null) continue;

        final distanceKm = _calculateDistanceKm(
          userLatitude: event.userLatitude,
          userLongitude: event.userLongitude,
          restaurantLatitude: restaurant.latitude,
          restaurantLongitude: restaurant.longitude,
        );

        if (distanceKm > _maxSearchRadiusKm) continue;

        searchResults.add(SearchResult(
          restaurant: restaurant,
          cheapestItem: matchingItem,
          distanceKm: distanceKm,
          isBestMatch: false,
        ));
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
      emit(SearchStateError(message: friendlyError(e)));
    } on FirestoreOperationException catch (e) {
      debugPrint('❌ [SEARCH] FirestoreOperation: ${e.message}');
      emit(SearchStateError(message: friendlyError(e)));
    } on LocationUnavailableException catch (e) {
      debugPrint('❌ [SEARCH] LocationUnavailable: ${e.message}');
      emit(SearchStateError(message: friendlyError(e)));
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

   // ============================================================
  // SMART CRAVING MATCHER
  // ============================================================
  // Scores each affordable item against the user's craving using
  // a tiered weighting:
  //
  //   1. Exact name match              → 100
  //   2. Item name starts with query   → 80
  //   3. Query is a whole word in name → 60
  //   4. Query is a substring          → 40
  //   5. Fuzzy match (1-2 typos)       → 20
  //
  // Plural handling ("pizzas" → "pizza") and token intersection
  // for multi-word queries ("chicken burger") are applied first.
  // ============================================================
  MenuItemModel? _findBestMatchingItem(
    List<MenuItemModel> affordableItems,
    String craving,
  ) {
    final query = craving.trim().toLowerCase();
    if (query.isEmpty) return affordableItems.first;

    // Tokenize query on whitespace.
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return affordableItems.first;

    MenuItemModel? best;
    int bestScore = 0;

    for (final item in affordableItems) {
      final name = item.name.toLowerCase();
      final nameTokens = _tokenize(name);

      int score = 0;

      // Full-query score (bonus for matching the whole phrase).
      final fullScore = _scorePhraseMatch(query, name);
      score += fullScore;

      // Token-level score: how many query tokens appear in the name?
      int tokenHits = 0;
      for (final qt in queryTokens) {
        final tokenScore = _scoreTokenInName(qt, nameTokens, name);
        if (tokenScore > 0) {
          tokenHits++;
          score += tokenScore;
        }
      }

      // Multi-word queries: reward items that match MOST of the tokens.
      if (queryTokens.length > 1 && tokenHits == queryTokens.length) {
        score += 30; // full-phrase bonus
      }

      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    // If nothing scored, return null → restaurant is skipped.
    // We don't fall back to "cheapest item" — a pizza search shouldn't
    // show a beef taco.
    return bestScore > 0 ? best : null;
  }

  /// Splits a string into lowercase word tokens.
  List<String> _tokenize(String input) {
    return input
        .split(RegExp(r'[\s\-_,\.]+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Score for the full query phrase against the item name.
  int _scorePhraseMatch(String query, String name) {
    if (name == query) return 100;
    if (name.startsWith(query)) return 80;
    // Whole-word match: "pizza" in "margherita pizza"
    final wordBoundary = RegExp(r'(^|\s)' + RegExp.escape(query) + r'(\s|$)');
    if (wordBoundary.hasMatch(name)) return 60;
    if (name.contains(query)) return 40;
    return 0;
  }

  /// Score for a single query token against the item name's tokens.
  int _scoreTokenInName(String queryToken, List<String> nameTokens, String name) {
    // Singular/plural normalization.
    final singular = _singularize(queryToken);

    for (final nt in nameTokens) {
      final ns = _singularize(nt);
      if (nt == queryToken || ns == singular) return 60; // exact word
      if (nt.startsWith(queryToken) || ns.startsWith(singular)) return 40;
      if (nt.contains(queryToken) || ns.contains(singular)) return 30;
      if (_levenshtein(nt, queryToken) <= 2) return 20; // typo tolerance
    }
    // Last-chance substring check on the full name.
    if (name.contains(queryToken)) return 30;
    return 0;
  }

  /// Crude English singularization — good enough for food names.
  String _singularize(String word) {
    if (word.length < 4) return word;
    if (word.endsWith('ies') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('es') && word.length > 4) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  /// Levenshtein distance — how many single-char edits to turn a into b.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      for (int k = 0; k <= b.length; k++) {
        prev[k] = curr[k];
      }
    }
    return prev[b.length];
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