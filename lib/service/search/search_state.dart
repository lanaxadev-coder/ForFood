// ============================================================
// SEARCH STATES
// ============================================================
// States emitted by SearchBloc in response to SearchEvents.
// ============================================================

import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/models/menu_item_model.dart';

/// Represents a single search result — a restaurant with
/// its cheapest matching menu item.
class SearchResult {
  /// The restaurant matching the search.
  final RestaurantModel restaurant;

  /// The cheapest menu item that matches the craving.
  final MenuItemModel cheapestItem;

  /// Distance from user to restaurant (in kilometers).
  final double distanceKm;

  /// Whether this is the best overall match.
  final bool isBestMatch;

  const SearchResult({
    required this.restaurant,
    required this.cheapestItem,
    required this.distanceKm,
    required this.isBestMatch,
  });
}

/// Base class for all Search states.
abstract class SearchState {
  const SearchState();
}

/// Initial state — no search performed yet.
class SearchStateInitial extends SearchState {
  const SearchStateInitial();
}

/// Loading state — search in progress.
class SearchStateLoading extends SearchState {
  const SearchStateLoading();
}

/// Success state — results found.
class SearchStateLoaded extends SearchState {
  /// Search results sorted by cheapest → nearest → highest rated.
  final List<SearchResult> results;

  /// Total number of results found.
  final int resultCount;

  const SearchStateLoaded({
    required this.results,
    required this.resultCount,
  });
}

/// Empty state — no results found.
class SearchStateEmpty extends SearchState {
  const SearchStateEmpty();
}

/// Error state — search failed.
class SearchStateError extends SearchState {
  final String message;

  const SearchStateError({required this.message});
}