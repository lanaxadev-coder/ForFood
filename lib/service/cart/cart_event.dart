// ============================================================
// CART EVENTS
// ============================================================
// Events dispatched to CartBloc to manage shopping cart state.
//
// The cart is the central state container for the user's
// ordering flow. Items are added from RestaurantDetailView,
// reviewed in CartView, and finalized in CheckoutView.
// ============================================================

import 'package:forfood/models/order_model.dart';

/// Base class for all Cart events.
abstract class CartEvent {
  const CartEvent();
}

/// Fired when user adds an item to the cart from
/// RestaurantDetailView.
class CartEventAddItem extends CartEvent {
  /// The menu item being added.
  final OrderItem item;

  /// The restaurant this item belongs to.
  /// Used to enforce single-restaurant cart rule.
  final String restaurantId;

  /// The restaurant's display name for order reference.
  final String restaurantName;

  const CartEventAddItem({
    required this.item,
    required this.restaurantId,
    required this.restaurantName,
  });
}

/// Fired when user removes an item from the cart.
class CartEventRemoveItem extends CartEvent {
  /// The menu item ID to remove.
  final String menuItemId;

  const CartEventRemoveItem({required this.menuItemId});
}

/// Fired when user increments quantity of an item.
class CartEventIncrementQuantity extends CartEvent {
  /// The menu item ID to increment.
  final String menuItemId;

  const CartEventIncrementQuantity({required this.menuItemId});
}

/// Fired when user decrements quantity of an item.
///
/// If quantity reaches 0, the item is removed.
class CartEventDecrementQuantity extends CartEvent {
  /// The menu item ID to decrement.
  final String menuItemId;

  const CartEventDecrementQuantity({required this.menuItemId});
}

/// Fired when user clears the entire cart.
class CartEventClear extends CartEvent {
  const CartEventClear();
}