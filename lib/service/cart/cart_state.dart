// ============================================================
// CART STATES
// ============================================================
// States emitted by CartBloc in response to CartEvents.
// ============================================================

import 'package:forfood/models/order_model.dart';

/// Base class for all Cart states.
abstract class CartState {
  const CartState();
}

/// Initial state — cart is empty.
class CartStateEmpty extends CartState {
  const CartStateEmpty();
}

/// State when cart has items.
class CartStateLoaded extends CartState {
  /// Items currently in the cart.
  final List<OrderItem> items;

  /// The restaurant ID for all items in the cart.
  final String restaurantId;

  /// The restaurant's display name.
  final String restaurantName;

  /// Total price of all items (sum of subtotals).
  final double total;

  const CartStateLoaded({
    required this.items,
    required this.restaurantId,
    required this.restaurantName,
    required this.total,
  });

  /// Number of items in the cart.
  int get itemCount => items.length;

  /// Total quantity across all items.
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Convenience copy method.
  CartStateLoaded copyWith({
    List<OrderItem>? items,
    String? restaurantId,
    String? restaurantName,
    double? total,
  }) {
    return CartStateLoaded(
      items: items ?? this.items,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      total: total ?? this.total,
    );
  }
}

/// Error state — cart operation failed.
class CartStateError extends CartState {
  final String message;

  const CartStateError({required this.message});
}