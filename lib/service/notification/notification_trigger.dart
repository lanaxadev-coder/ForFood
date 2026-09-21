// ============================================================
// NOTIFICATION TRIGGER SERVICE
// ============================================================
// Helper service that creates notifications when order events
// occur. Called from OrderBloc after status changes.
//
// Triggers:
//   - Order placed → notify restaurant
//   - Order accepted → notify user
//   - Order rejected → notify user
//   - Order cancelled → notify restaurant
//   - Order completed → notify user
// ============================================================
// ============================================================
// NOTIFICATION TRIGGER SERVICE
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:forfood/models/notification_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/models/review_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';

class NotificationTriggerService {
  final FirestoreProvider _firestoreProvider;

  NotificationTriggerService(this._firestoreProvider);

  // ============================================================
  // ORDER EVENTS
  // ============================================================

  /// Order placed by user → notify restaurant.
/// Order placed by user → notify the restaurant owner.
Future<void> onOrderPlaced(OrderModel order) async {
  String recipientId;
  try {
    final restaurant =
        await _firestoreProvider.getRestaurantById(order.restaurantId);
    recipientId = restaurant.ownerId;
  } catch (_) {
    recipientId = order.restaurantId;
  }

  await _createNotification(
    recipientId: recipientId,
    type: NotificationType.orderPlaced,
    title: 'New Order',
    message:
        '${order.customerName} placed an order for ${order.items.length} item${order.items.length == 1 ? '' : 's'}',
    orderId: order.id,
  );
}
  /// Restaurant accepted → notify user (in-app only — no push).
  Future<void> onOrderAccepted(OrderModel order) async {
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.orderAccepted,
      title: 'Order Accepted',
      message: '${order.restaurantName} accepted your order.',
      orderId: order.id,
    );
  }

  /// 👈 NEW — restaurant started preparing → notify user.
  Future<void> onOrderPreparing(OrderModel order) async {
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.orderAccepted, // reuse "accepted" styling
      title: 'Preparing your order',
      message: '${order.restaurantName} is cooking your food now.',
      orderId: order.id,
    );
  }

  /// 👈 NEW — order is ready for pickup → notify user (important).
  Future<void> onOrderReadyForPickup(OrderModel order) async {
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.orderReady,
      title: 'Ready for Pickup!',
      message: 'Your order is ready. Head over to ${order.restaurantName}.',
      orderId: order.id,
    );
  }

  /// 👈 NEW — order is out for delivery → notify user (important).
  Future<void> onOrderOutForDelivery(OrderModel order) async {
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.orderOutForDelivery,
      title: 'Out for Delivery',
      message: '${order.restaurantName} is on the way. Get ready!',
      orderId: order.id,
    );
  }

  /// Restaurant rejected → notify user.
  Future<void> onOrderRejected(OrderModel order) async {
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.orderRejected,
      title: 'Order Rejected',
      message: '${order.restaurantName} rejected your order.',
      orderId: order.id,
    );
  }

  /// User cancelled → notify restaurant.
  /// User cancelled → notify restaurant owner.
Future<void> onOrderCancelled(OrderModel order, String? reason) async {
  String recipientId;
  try {
    final restaurant =
        await _firestoreProvider.getRestaurantById(order.restaurantId);
    recipientId = restaurant.ownerId;
  } catch (_) {
    recipientId = order.restaurantId;
  }

  await _createNotification(
    recipientId: recipientId,
    type: NotificationType.orderCancelled,
    title: 'Order Cancelled',
    message: '${order.customerName} cancelled their order'
        '${reason != null ? ': $reason' : ''}',
    orderId: order.id,
  );
}

  /// Order completed → notify user (in-app) + schedule "rate your order"
  /// prompt 30 minutes later.
  Future<void> onOrderCompleted(OrderModel order) async {
    // 1. Immediate completion notification
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.orderCompleted,
      title: 'Order Delivered',
      message: 'Your order from ${order.restaurantName} has been delivered.',
      orderId: order.id,
    );

    // 2. Delayed "rate your order" prompt — hidden until 30 min later
    await _createNotification(
      recipientId: order.userId,
      type: NotificationType.reviewAdded, // reusing "review" styling
      title: 'How was your food?',
      message:
          'Rate your order from ${order.restaurantName} — it takes 10 seconds.',
      orderId: order.id,
      deliverAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  // ============================================================
  // REVIEW EVENTS  👈 NEW
  // ============================================================

  /// User added a review → notify the restaurant.
  /// User added a review → notify the restaurant owner.
Future<void> onReviewAdded({
  required String restaurantId,
  required String restaurantName,
  required ReviewModel review,
}) async {
  // Resolve the owner's auth UID from the restaurant doc
  String recipientId;
  try {
    final restaurant =
        await _firestoreProvider.getRestaurantById(restaurantId);
    recipientId = restaurant.ownerId;
  } catch (_) {
    // Fallback if lookup fails — notification just won't be seen
    recipientId = restaurantId;
  }

  final stars = '⭐' * review.rating;

  await _createNotification(
    recipientId: recipientId,
    type: NotificationType.reviewAdded,
    title: 'New Review',
    message:
        '${review.userName} gave $stars — "${_truncate(review.comment, 60)}"',
    orderId: null,
  );
}

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  // ============================================================
  // PRIVATE HELPER
  // ============================================================

  Future<void> _createNotification({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String message,
    String? orderId,
    DateTime? deliverAt,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        recipientId: recipientId,
        type: type,
        title: title,
        message: message,
        orderId: orderId,
        isRead: false,
        createdAt: DateTime.now(),
        deliverAt: deliverAt,
      );

      await _firestoreProvider.createNotification(notification);
    } on FirestoreOperationException {
      debugPrint('Failed to create notification for $recipientId');
    }
  }
}