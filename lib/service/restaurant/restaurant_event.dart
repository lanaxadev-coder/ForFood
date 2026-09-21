// ============================================================
// RESTAURANT EVENTS
// ============================================================
// Events dispatched to RestaurantBloc to manage restaurant data.
// ============================================================

import 'package:forfood/models/restaurant_model.dart';

/// Base class for all Restaurant events.
abstract class RestaurantEvent {
  const RestaurantEvent();
}

/// Fired to fetch the restaurant by owner's Firebase Auth UID.
class RestaurantEventFetchByOwnerId extends RestaurantEvent {
  final String ownerId;

  const RestaurantEventFetchByOwnerId({required this.ownerId});
}

/// Fired to fetch the restaurant by Firestore document ID.
class RestaurantEventFetchById extends RestaurantEvent {
  final String restaurantId;

  const RestaurantEventFetchById({required this.restaurantId});
}

/// Fired to update the restaurant's delivery status.
class RestaurantEventUpdateDeliveryStatus extends RestaurantEvent {
  final bool isDeliveryEnabled;

  const RestaurantEventUpdateDeliveryStatus({
    required this.isDeliveryEnabled,
  });
}

// ============================================================
// INTERNAL STREAM EVENTS
// ============================================================

class RestaurantEventStreamUpdated extends RestaurantEvent {
  final RestaurantModel restaurant;
  const RestaurantEventStreamUpdated({required this.restaurant});
}

class RestaurantEventStreamError extends RestaurantEvent {
  final String message;
  const RestaurantEventStreamError({required this.message});
}

class RestaurantEventTimeout extends RestaurantEvent {
  const RestaurantEventTimeout();
}