// ============================================================
// NOTIFICATION MODEL
// ============================================================
// Represents a notification sent to a user or restaurant.
// Maps directly to Firestore documents at:
//   /notifications/{notificationId}
//
// Notifications are triggered by order events:
//   - Order placed → notified restaurant
//   - Order accepted/rejected → notified user
//   - Order delivered → notified user
//   - Order cancelled → notified both parties
//   - Review added → notified restaurant
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the type of notification.
enum NotificationType {
  /// New order placed by a user.
  orderPlaced,

  /// Order accepted by restaurant.
  orderAccepted,

  /// Order rejected by restaurant.
  orderRejected,

  /// Order ready for pickup.
  orderReady,

  /// Order out for delivery.
  orderOutForDelivery,

  /// Order delivered/picked up.
  orderCompleted,

  /// Order cancelled by user.
  orderCancelled,

  /// New review added.
  reviewAdded,
  chatMessage;              // ✅ NEW

  /// Converts to Firestore string representation.
  String get name => toString().split('.').last;

  /// Creates from Firestore string value.
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.orderPlaced,
    );
  }

  /// Human-readable title for the notification.
  String get title {
    switch (this) {
      case NotificationType.orderPlaced:
        return 'New Order';
      case NotificationType.orderAccepted:
        return 'Order Accepted';
      case NotificationType.orderRejected:
        return 'Order Rejected';
      case NotificationType.orderReady:
        return 'Order Ready';
      case NotificationType.orderOutForDelivery:
        return 'Out for Delivery';
      case NotificationType.orderCompleted:
        return 'Order Delivered';
      case NotificationType.orderCancelled:
        return 'Order Cancelled';
      case NotificationType.reviewAdded:
        return 'New Review';
          case NotificationType.chatMessage:      // ✅ NEW
        return 'New message';
    }
  }

  /// Icon asset path for this notification type.
  String get iconPath {
    switch (this) {
      case NotificationType.orderPlaced:
        return 'assets/icons/order.svg';
      case NotificationType.orderAccepted:
        return 'assets/icons/check-circle.svg';
      case NotificationType.orderRejected:
        return 'assets/icons/cancel-circle.svg';
      case NotificationType.orderReady:
        return 'assets/icons/ready.svg';
      case NotificationType.orderOutForDelivery:
        return 'assets/icons/delivery.svg';
      case NotificationType.orderCompleted:
        return 'assets/icons/completed.svg';
      case NotificationType.orderCancelled:
        return 'assets/icons/cancel-circle.svg';
      case NotificationType.reviewAdded:
        return 'assets/icons/star.svg';
         case NotificationType.chatMessage:      // ✅ NEW
        return 'assets/icons/chat.svg';  
    }
  }
}

/// Domain model representing a notification.
class NotificationModel {
  /// Firestore document ID.
  final String id;

  /// Firebase Auth UID of the recipient.
  final String recipientId;

  /// Type of notification.
  final NotificationType type;

  /// Short title for display.
  final String title;

  /// Detailed message body.
  final String message;

  /// Optional order ID for deep-linking.
  final String? orderId;

  /// Whether the notification has been read.
  final bool isRead;

  /// Timestamp of when the notification was created.
  final DateTime createdAt;
final DateTime? deliverAt;
  /// Creates a new [NotificationModel] instance.
  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.orderId,
    required this.isRead,
    required this.createdAt,
      this.deliverAt,                    // 👈 NEW

  });

  // ============================================================
  // FIRESTORE CONVERSION
  // ============================================================

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'type': type.name,
      'title': title,
      'message': message,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
          'deliverAt': deliverAt != null ? Timestamp.fromDate(deliverAt!) : null,  // 👈 NEW

    };
  }

  /// Creates from Firestore document.
  factory NotificationModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final recipientId = map['recipientId'] as String?;
    final typeString = map['type'] as String?;
    final title = map['title'] as String?;
    final message = map['message'] as String?;
    final isRead = map['isRead'] as bool?;
    final createdAt = map['createdAt'] as Timestamp?;

    if (recipientId == null) {
      throw StateError('NotificationModel.fromMap: "recipientId" is required');
    }
    if (typeString == null) {
      throw StateError('NotificationModel.fromMap: "type" is required');
    }
    if (title == null) {
      throw StateError('NotificationModel.fromMap: "title" is required');
    }
    if (message == null) {
      throw StateError('NotificationModel.fromMap: "message" is required');
    }
    if (isRead == null) {
      throw StateError('NotificationModel.fromMap: "isRead" is required');
    }
    if (createdAt == null) {
      throw StateError('NotificationModel.fromMap: "createdAt" is required');
    }

    return NotificationModel(
      id: id,
      recipientId: recipientId,
      type: NotificationType.fromString(typeString),
      title: title,
      message: message,
      orderId: map['orderId'] as String?,
      isRead: isRead,
      createdAt: createdAt.toDate(),
      deliverAt: map['deliverAt'] != null                          // 👈 NEW
      ? (map['deliverAt'] as Timestamp).toDate()
      : null,
    );
  }

  // ============================================================
  // IMMUTABILITY SUPPORT
  // ============================================================

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      message: message,
      orderId: orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
          deliverAt: deliverAt ?? this.deliverAt,   // 👈 NEW

    );
  }

  // ============================================================
  // EQUALITY & HASHING
  // ============================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.recipientId == recipientId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.orderId == orderId &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.deliverAt == deliverAt; 
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      recipientId,
      type,
      title,
      message,
      orderId,
      isRead,
      createdAt,
      deliverAt , 
    );
  }

  // ============================================================
  // DEBUGGING
  // ============================================================

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, '
        'isRead: $isRead, createdAt: $createdAt)';
  }
}