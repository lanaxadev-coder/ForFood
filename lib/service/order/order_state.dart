// ============================================================
// ORDER STATES
// ============================================================
// States emitted by OrderBloc in response to OrderEvents.
// ============================================================

import 'package:forfood/models/order_model.dart';

/// Base class for all Order states.
abstract class OrderState {
  const OrderState();
}

/// Initial state — no orders loaded yet.
class OrderStateInitial extends OrderState {
  const OrderStateInitial();
}

/// Loading state — fetching or updating orders.
class OrderStateLoading extends OrderState {
  const OrderStateLoading();
}

/// State when orders are loaded.
class OrderStateLoaded extends OrderState {
  /// List of orders for display.
  final List<OrderModel> orders;

  const OrderStateLoaded({required this.orders});

  /// Convenience copy method.
  OrderStateLoaded copyWith({List<OrderModel>? orders}) {
    return OrderStateLoaded(orders: orders ?? this.orders);
  }
}

/// State when a single order operation succeeds.
class OrderStateSuccess extends OrderState {
  final String message;
  final OrderModel? order;

  /// 👈 The last-known list of orders. Carried through action successes
  /// so the UI never falls into an empty state when cancelling / accepting /
  /// rejecting. When null, the UI keeps whatever it was rendering.
  final List<OrderModel>? currentOrders;

  const OrderStateSuccess({
    required this.message,
    this.order,
    this.currentOrders,
  });
}
/// Error state — order operation failed.
class OrderStateError extends OrderState {
  final String message;

  const OrderStateError({required this.message});
}