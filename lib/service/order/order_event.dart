// ============================================================
// ORDER EVENTS
// ============================================================
// Events dispatched to OrderBloc to manage orders.
//
// Handles both user-side operations (place, cancel) and
// restaurant-side operations (accept, reject, update status).
// ============================================================

import 'package:forfood/models/order_model.dart';

/// Base class for all Order events.
abstract class OrderEvent {
  const OrderEvent();
}

// ============================================================
// USER-SIDE EVENTS
// ============================================================

/// Fired when user taps "Place Order" on CheckoutView.
class OrderEventPlaceOrder extends OrderEvent {
  /// The complete order to place.
  final OrderModel order;

  const OrderEventPlaceOrder({required this.order});
}

/// Fired when user cancels an active order.
class OrderEventCancelOrder extends OrderEvent {
  /// The order ID to cancel.
  final String orderId;

  /// User-provided reason for cancellation.
  final String? reason;

  const OrderEventCancelOrder({
    required this.orderId,
    this.reason,
  });
}

/// Fired when user fetches their order history.
class OrderEventFetchUserOrders extends OrderEvent {
  /// The user's Firebase Auth UID.
  final String userId;

  const OrderEventFetchUserOrders({required this.userId});
}

/// Fired when user taps "Order Again" on a completed order.
class OrderEventReorderItems extends OrderEvent {
  /// The original order to reorder from.
  final OrderModel originalOrder;

  const OrderEventReorderItems({required this.originalOrder});
}

// ============================================================
// RESTAURANT-SIDE EVENTS
// ============================================================

/// Fired when restaurant fetches incoming orders.
class OrderEventFetchRestaurantOrders extends OrderEvent {
  /// The restaurant's Firestore document ID.
  final String restaurantId;

  const OrderEventFetchRestaurantOrders({required this.restaurantId});
}

/// Fired when restaurant accepts an order.
class OrderEventAcceptOrder extends OrderEvent {
  /// The order ID to accept.
  final String orderId;

  const OrderEventAcceptOrder({required this.orderId});
}

/// Fired when restaurant rejects an order.
class OrderEventRejectOrder extends OrderEvent {
  /// The order ID to reject.
  final String orderId;

  const OrderEventRejectOrder({required this.orderId});
}

/// Fired when restaurant updates order status.
class OrderEventUpdateStatus extends OrderEvent {
  /// The order ID to update.
  final String orderId;

  /// The new status to set.
  final OrderStatus newStatus;

  const OrderEventUpdateStatus({
    required this.orderId,
    required this.newStatus,
  });
}


/// Fired when restaurant taps the next step button.
class OrderEventProgressToNextStage extends OrderEvent {
  final String orderId;
  final int? estimatedPrepMinutes; // ✅ Added — set when accepting

  const OrderEventProgressToNextStage({
    required this.orderId,
    this.estimatedPrepMinutes,
  });
}// ============================================================
// INTERNAL STREAM EVENTS
// ============================================================

/// Internal: the orders stream emitted new data.
class OrderEventStreamUpdated extends OrderEvent {
  final List<OrderModel> orders;

  const OrderEventStreamUpdated({required this.orders});
}

/// Internal: the orders stream failed.
class OrderEventStreamError extends OrderEvent {
  final String message;

  const OrderEventStreamError({required this.message});
}

/// Internal: safety timeout fired — no data received.
class OrderEventTimeout extends OrderEvent {
  const OrderEventTimeout();
}