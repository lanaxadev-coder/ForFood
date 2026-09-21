// ============================================================
// SEARCH EVENTS
// ============================================================
// Events dispatched to SearchBloc to perform budget-first
// food discovery searches.
//
// The search algorithm sorts results by:
//   1. Cheapest First (Price ↑)
//   2. Then Nearest (Distance ↑)
//   3. Then Highest Rated (Rating ↓)
// ============================================================

/// Base class for all Search events.
abstract class SearchEvent {
  const SearchEvent();
}

/// Fired when user taps "Search" on SearchView.
class SearchEventPerformSearch extends SearchEvent {
  /// What the user is craving (e.g., "pizza", "burger").
  final String craving;

  /// Maximum budget in USD (e.g., 10.0 for $10).
  final double maxBudget;

  /// User's current latitude (for distance calculation).
  final double userLatitude;

  /// User's current longitude (for distance calculation).
  final double userLongitude;

  const SearchEventPerformSearch({
    required this.craving,
    required this.maxBudget,
    required this.userLatitude,
    required this.userLongitude,
  });
}

/// Fired when user clears search results.
class SearchEventClearResults extends SearchEvent {
  const SearchEventClearResults();
}