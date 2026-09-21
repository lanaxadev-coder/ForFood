// ============================================================
// RESTAURANT STATES
// ============================================================
// States emitted by RestaurantBloc in response to RestaurantEvents.
// ============================================================

import 'package:forfood/models/restaurant_model.dart';

/// Base class for all Restaurant states.
abstract class RestaurantState {
  const RestaurantState();
}

/// Initial state — no restaurant loaded.
class RestaurantStateInitial extends RestaurantState {
  const RestaurantStateInitial();
}

/// Loading state — fetching restaurant data.
class RestaurantStateLoading extends RestaurantState {
  const RestaurantStateLoading();
}

/// Loaded state — restaurant data fetched.
class RestaurantStateLoaded extends RestaurantState {
  final RestaurantModel restaurant;

  const RestaurantStateLoaded({required this.restaurant});
}

/// Error state — restaurant fetch failed.
class RestaurantStateError extends RestaurantState {
  final String message;

  const RestaurantStateError({required this.message});
}