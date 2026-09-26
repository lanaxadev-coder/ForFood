// ============================================================
// ORDER BLOC — WITH NOTIFICATION TRIGGERS + SAFETY TIMEOUT
// + Preserves order list across all action events
// ============================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/cart/cart_event.dart';
import 'package:forfood/service/cart/cart_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/notification/notification_trigger.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/utilities/friendly_error.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final FirestoreProvider _firestoreProvider;
  final CartBloc _cartBloc;
  late final NotificationTriggerService _notificationTrigger;
  StreamSubscription<List<OrderModel>>? _userOrdersSubscription;
  StreamSubscription<List<OrderModel>>? _restaurantOrdersSubscription;
  Timer? _timeoutTimer;

  /// 👈 Cache of the last-emitted order list. Passed through
  /// action Success states so the UI keeps rendering orders
  /// after cancel / accept / reject / reorder.
  List<OrderModel> _lastLoadedOrders = [];

  OrderBloc(FirestoreProvider firestoreProvider, CartBloc cartBloc)
      : _firestoreProvider = firestoreProvider,
        _cartBloc = cartBloc,
        super(const OrderStateInitial()) {
    _notificationTrigger = NotificationTriggerService(firestoreProvider);

    on<OrderEventPlaceOrder>(_onPlaceOrder);
    on<OrderEventCancelOrder>(_onCancelOrder);
    on<OrderEventFetchUserOrders>(_onFetchUserOrders);
    on<OrderEventReorderItems>(_onReorderItems);
    on<OrderEventFetchRestaurantOrders>(_onFetchRestaurantOrders);
    on<OrderEventAcceptOrder>(_onAcceptOrder);
    on<OrderEventRejectOrder>(_onRejectOrder);
    on<OrderEventUpdateStatus>(_onUpdateStatus);
    on<OrderEventProgressToNextStage>(_onProgressToNextStage);

    // Internal stream handlers
    on<OrderEventStreamUpdated>(_onStreamUpdated);
    on<OrderEventStreamError>(_onStreamError);
    on<OrderEventTimeout>(_onTimeout);
  }

  // ============================================================
  // USER-SIDE EVENT HANDLERS
  // ============================================================

  Future<void> _onPlaceOrder(
    OrderEventPlaceOrder event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrderStateLoading) return;

    if (event.order.items.isEmpty) {
      emit(const OrderStateError(
        message: 'Your cart is empty. Add items before placing an order.',
      ));
      return;
    }

    emit(const OrderStateLoading());

    try {
      final createdOrder = await _firestoreProvider.createOrder(event.order);
      await _notificationTrigger.onOrderPlaced(createdOrder);
      emit(OrderStateSuccess(
        message: 'Order placed successfully',
        order: createdOrder,
      ));
    } on FirestoreOperationException catch (e) {
      emit(OrderStateError(message: friendlyError(e)));
    } catch (e) {
      emit(OrderStateError(message: 'Failed to place order: $e'));
    }
  }

  Future<void> _onCancelOrder(
    OrderEventCancelOrder event,
    Emitter<OrderState> emit,
  ) async {
    // No emit(Loading) — keeps the list visible during the operation

    try {
      await _firestoreProvider.updateOrderStatus(
        orderId: event.orderId,
        newStatus: OrderStatus.cancelled,
        cancellationReason: event.reason,
      );

      final order = await _firestoreProvider.getOrderById(event.orderId);
      await _notificationTrigger.onOrderCancelled(order, event.reason);

      emit(OrderStateSuccess(
        message: 'Order cancelled successfully',
        currentOrders: _lastLoadedOrders, // 👈 preserve list
      ));
    } on FirestoreOperationException catch (e) {
      emit(OrderStateError(message: e.message));
    } catch (e) {
      emit(OrderStateError(message: 'Failed to cancel order: $e'));
    }
  }

  Future<void> _onFetchUserOrders(
    OrderEventFetchUserOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderStateLoading());

    await _userOrdersSubscription?.cancel();
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        add(const OrderEventTimeout());
      }
    });

    _userOrdersSubscription = _firestoreProvider
        .streamOrdersByUserId(event.userId)
        .listen(
      (orders) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(OrderEventStreamUpdated(orders: orders));
        }
      },
      onError: (error) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(OrderEventStreamError(message: error.toString()));
        }
      },
      onDone: () {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(const OrderEventStreamUpdated(orders: []));
        }
      },
    );
  }
Future<void> _onReorderItems(
  OrderEventReorderItems event,
  Emitter<OrderState> emit,
) async {
  final originalOrder = event.originalOrder;

  // ── Precondition: cart must be empty or from the same restaurant ──
  final cartState = _cartBloc.state;
  if (cartState is CartStateLoaded &&
      cartState.restaurantId != originalOrder.restaurantId) {
    emit(const OrderStateError(
      message:
          'Your cart already has items from another restaurant. '
          'Clear it first, or check out the current cart.',
    ));
    return;
  }

  for (final item in originalOrder.items) {
    _cartBloc.add(
      CartEventAddItem(
        item: OrderItem(
          menuItemId: item.menuItemId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          imageUrl: item.imageUrl,
          dateTime: DateTime.now(),
        ),
        restaurantId: originalOrder.restaurantId,
        restaurantName: originalOrder.restaurantName,
      ),
    );
  }

  emit(OrderStateSuccess(
    message:
        '${originalOrder.items.length} item${originalOrder.items.length == 1 ? '' : 's'} added to cart',
    currentOrders: _lastLoadedOrders,
  ));
}
  // ============================================================
  // RESTAURANT-SIDE EVENT HANDLERS
  // ============================================================

  Future<void> _onFetchRestaurantOrders(
    OrderEventFetchRestaurantOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderStateLoading());

    await _restaurantOrdersSubscription?.cancel();
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        add(const OrderEventTimeout());
      }
    });

    _restaurantOrdersSubscription = _firestoreProvider
        .streamOrdersByRestaurantId(event.restaurantId)
        .listen(
      (orders) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(OrderEventStreamUpdated(orders: orders));
        }
      },
      onError: (error) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(OrderEventStreamError(message: error.toString()));
        }
      },
      onDone: () {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(const OrderEventStreamUpdated(orders: []));
        }
      },
    );
  }

  Future<void> _onAcceptOrder(
    OrderEventAcceptOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _firestoreProvider.updateOrderStatus(
        orderId: event.orderId,
        newStatus: OrderStatus.accepted,
      );

      final order = await _firestoreProvider.getOrderById(event.orderId);
      await _notificationTrigger.onOrderAccepted(order);

      emit(OrderStateSuccess(
        message: 'Order accepted',
        currentOrders: _lastLoadedOrders, // 👈 preserve list
      ));
    } on FirestoreOperationException catch (e) {
      emit(OrderStateError(message: friendlyError(e)));
    } catch (e) {
      emit(OrderStateError(message: 'Failed to accept order: $e'));
    }
  }

  Future<void> _onRejectOrder(
    OrderEventRejectOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _firestoreProvider.updateOrderStatus(
        orderId: event.orderId,
        newStatus: OrderStatus.rejected,
      );

      final order = await _firestoreProvider.getOrderById(event.orderId);
      await _notificationTrigger.onOrderRejected(order);

      emit(OrderStateSuccess(
        message: 'Order rejected',
        currentOrders: _lastLoadedOrders, // 👈 preserve list
      ));
    } on FirestoreOperationException catch (e) {
      emit(OrderStateError(message: friendlyError(e)));
    } catch (e) {
      emit(OrderStateError(message: 'Failed to reject order: $e'));
    }
  }Future<void> _onUpdateStatus(
  OrderEventUpdateStatus event,
  Emitter<OrderState> emit,
) async {
  try {
    await _firestoreProvider.updateOrderStatus(
      orderId: event.orderId,
      newStatus: event.newStatus,
    );

    // Fetch fresh order for notification context
    final order = await _firestoreProvider.getOrderById(event.orderId);

    // 👈 Fire the right notification per status
    switch (event.newStatus) {
      case OrderStatus.accepted:
        await _notificationTrigger.onOrderAccepted(order);
        break;
      case OrderStatus.preparing:
        await _notificationTrigger.onOrderPreparing(order);
        break;
      case OrderStatus.readyForPickup:
        await _notificationTrigger.onOrderReadyForPickup(order);
        break;
      case OrderStatus.outForDelivery:
        await _notificationTrigger.onOrderOutForDelivery(order);
        break;
      case OrderStatus.completed:
        await _notificationTrigger.onOrderCompleted(order);
        break;
      default:
        break;
    }

    emit(OrderStateSuccess(
      message: 'Order status updated to ${event.newStatus.displayName}',
      currentOrders: _lastLoadedOrders,
    ));
  } on FirestoreOperationException catch (e) {
    emit(OrderStateError(message: e.message));
  } catch (e) {
    emit(OrderStateError(message: 'Failed to update order status: $e'));
  }
}
Future<void> _onProgressToNextStage(
  OrderEventProgressToNextStage event,
  Emitter<OrderState> emit,
) async {
  try {
    final order = await _firestoreProvider.getOrderById(event.orderId);
    final nextStatus = order.status.nextStatus;

    if (nextStatus == null) {
      emit(const OrderStateError(message: 'Order is already completed'));
      return;
    }

    await _firestoreProvider.updateOrderStatus(
      orderId: event.orderId,
      newStatus: nextStatus,
      estimatedPrepMinutes: event.estimatedPrepMinutes,
    );

    // 👈 Fire the right notification per status
    switch (nextStatus) {
      case OrderStatus.accepted:
        await _notificationTrigger.onOrderAccepted(order);
        break;
      case OrderStatus.preparing:
        await _notificationTrigger.onOrderPreparing(order);
        break;
      case OrderStatus.readyForPickup:
        await _notificationTrigger.onOrderReadyForPickup(order);
        break;
      case OrderStatus.outForDelivery:
        await _notificationTrigger.onOrderOutForDelivery(order);
        break;
      case OrderStatus.completed:
        await _notificationTrigger.onOrderCompleted(order);
        break;
      default:
        break;
    }

    emit(OrderStateSuccess(
      message: 'Order status updated to ${nextStatus.displayName}',
      currentOrders: _lastLoadedOrders,
    ));
  } on FirestoreOperationException catch (e) {
    emit(OrderStateError(message: friendlyError(e)));
  }
}
  // ============================================================
  // INTERNAL STREAM HANDLERS
  // ============================================================

  void _onStreamUpdated(
    OrderEventStreamUpdated event,
    Emitter<OrderState> emit,
  ) {
    _lastLoadedOrders = event.orders; // 👈 cache
    emit(OrderStateLoaded(orders: event.orders));
  }

  void _onStreamError(
    OrderEventStreamError event,
    Emitter<OrderState> emit,
  ) {
    emit(OrderStateError(message: event.message));
  }

  void _onTimeout(
    OrderEventTimeout event,
    Emitter<OrderState> emit,
  ) {
    // Only if still loading (no data arrived)
    if (state is OrderStateLoading) {
      emit(const OrderStateLoaded(orders: []));
    }
  }

  @override
  Future<void> close() {
    _userOrdersSubscription?.cancel();
    _restaurantOrdersSubscription?.cancel();
    _timeoutTimer?.cancel();
    return super.close();
  }
}