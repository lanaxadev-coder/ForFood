// ============================================================
// RESTAURANT LIST EVENTS
// ============================================================
// Events for fetching restaurants on the user home screen.
// Includes optional user location for distance sorting.
// ============================================================

/// Base class for all RestaurantList events.
abstract class RestaurantListEvent {
  const RestaurantListEvent();
}

/// Fired to fetch recommended restaurants.
/// Sorted: Featured → Highest Rating → Nearest.
class RestaurantListEventFetchRecommendations extends RestaurantListEvent {
  /// User's current latitude (for distance sorting).
  final double? userLatitude;

  /// User's current longitude (for distance sorting).
  final double? userLongitude;

  const RestaurantListEventFetchRecommendations({
    this.userLatitude,
    this.userLongitude,
  });
}

/// Fired to fetch high demand restaurants.
/// Sorted: Highest Order Count → Highest Rating → Nearest.
class RestaurantListEventFetchHighDemands extends RestaurantListEvent {
  /// User's current latitude (for distance sorting).
  final double? userLatitude;

  /// User's current longitude (for distance sorting).
  final double? userLongitude;

  const RestaurantListEventFetchHighDemands({
    this.userLatitude,
    this.userLongitude,
  });
}