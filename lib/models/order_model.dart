// ============================================================
// ORDER MODEL — COMPLETE WITH ALL GETTERS
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  readyForPickup,
  outForDelivery,
  completed,
  cancelled,
  rejected;

  String get name => toString().split('.').last;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isActive {
    return this == OrderStatus.pending ||
        this == OrderStatus.accepted ||
        this == OrderStatus.preparing ||
        this == OrderStatus.readyForPickup ||
        this == OrderStatus.outForDelivery;
  }

  bool get isTerminal {
    return this == OrderStatus.completed ||
        this == OrderStatus.cancelled ||
        this == OrderStatus.rejected;
  }

  bool get isCompleted => this == OrderStatus.completed;
  bool get isCancelled => this == OrderStatus.cancelled;
  bool get isRejected => this == OrderStatus.rejected;

  OrderStatus? get nextStatus {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.readyForPickup;
      case OrderStatus.readyForPickup:
        return OrderStatus.completed;
      case OrderStatus.outForDelivery:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  String? get nextActionLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'Accept Order';
      case OrderStatus.accepted:
        return 'Start Preparing';
      case OrderStatus.preparing:
        return 'Mark as Ready';
      case OrderStatus.readyForPickup:
        return 'Mark as Picked Up';
      case OrderStatus.outForDelivery:
        return 'Mark as Delivered';
      default:
        return null;
    }
  }
}

enum DeliveryMethod {
  pickup,
  delivery;

  String get name => toString().split('.').last;

  static DeliveryMethod fromString(String value) {
    return DeliveryMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => DeliveryMethod.pickup,
    );
  }
}

enum PaymentMethod {
  cashOnDelivery;

  String get name => toString().split('.').last;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.cashOnDelivery,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final DateTime dateTime;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.dateTime,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final menuItemId = map['menuItemId'] as String?;
    final name = map['name'] as String?;
    final price = map['price'] as num?;
    final quantity = map['quantity'] as int?;

    if (menuItemId == null) {
      throw StateError('OrderItem.fromMap: "menuItemId" is required');
    }
    if (name == null) {
      throw StateError('OrderItem.fromMap: "name" is required');
    }
    if (price == null) {
      throw StateError('OrderItem.fromMap: "price" is required');
    }
    if (quantity == null) {
      throw StateError('OrderItem.fromMap: "quantity" is required');
    }

    return OrderItem(
      menuItemId: menuItemId,
      name: name,
      price: price.toDouble(),
      quantity: quantity,
      imageUrl: map['imageUrl'] as String?,
      dateTime: (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  OrderItem copyWith({int? quantity}) {
    return OrderItem(
      menuItemId: menuItemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      dateTime: dateTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.menuItemId == menuItemId &&
        other.name == name &&
        other.price == price &&
        other.quantity == quantity &&
        other.imageUrl == imageUrl &&
        other.dateTime == dateTime;
  }

  @override
  int get hashCode {
    return Object.hash(menuItemId, name, price, quantity, imageUrl, dateTime);
  }

  @override
  String toString() {
    return 'OrderItem(menuItemId: $menuItemId, name: $name, price: $price, quantity: $quantity)';
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;
  final String? deliveryAddress;
  final String customerName;
  final String? customerPhone;
  final String customerEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? estimatedPrepMinutes;
  final String? cancellationReason;
  final List<String> unavailableItems;

  // ✅ NEW — chat tracking
  final DateTime? lastMessageAt;
  final String? lastMessageBy;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryMethod,
    required this.paymentMethod,
    this.deliveryAddress,
    required this.customerName,
    this.customerPhone,
    required this.customerEmail,
    required this.createdAt,
    this.updatedAt,
    this.estimatedPrepMinutes,
    this.unavailableItems = const [],
    this.cancellationReason,
    this.lastMessageAt,        // ✅ NEW
    this.lastMessageBy,        // ✅ NEW
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status.name,
      'deliveryMethod': deliveryMethod.name,
      'paymentMethod': paymentMethod.name,
      'deliveryAddress': deliveryAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'unavailableItems': unavailableItems,
      'customerEmail': customerEmail,
      'estimatedPrepMinutes': estimatedPrepMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancellationReason': cancellationReason,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,                                            // ✅ NEW
      'lastMessageBy': lastMessageBy,                        // ✅ NEW
    };
  }

  factory OrderModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final userId = map['userId'] as String?;
    final restaurantId = map['restaurantId'] as String?;
    final restaurantName = map['restaurantName'] as String?;
    final itemsList = map['items'] as List?;
    final total = map['total'] as num?;
    final estimatedPrepMinutes = map['estimatedPrepMinutes'] as int?;
    final statusString = map['status'] as String?;
    final deliveryMethodString = map['deliveryMethod'] as String?;
    final paymentMethodString = map['paymentMethod'] as String?;
    final customerName = map['customerName'] as String?;
    final customerEmail = map['customerEmail'] as String?;
    final createdAt = map['createdAt'] as Timestamp?;

    if (userId == null) {
      throw StateError('OrderModel.fromMap: "userId" is required');
    }
    if (restaurantId == null) {
      throw StateError('OrderModel.fromMap: "restaurantId" is required');
    }
    if (restaurantName == null) {
      throw StateError('OrderModel.fromMap: "restaurantName" is required');
    }
    if (itemsList == null) {
      throw StateError('OrderModel.fromMap: "items" is required');
    }
    if (total == null) {
      throw StateError('OrderModel.fromMap: "total" is required');
    }
    if (statusString == null) {
      throw StateError('OrderModel.fromMap: "status" is required');
    }
    if (deliveryMethodString == null) {
      throw StateError('OrderModel.fromMap: "deliveryMethod" is required');
    }
    if (paymentMethodString == null) {
      throw StateError('OrderModel.fromMap: "paymentMethod" is required');
    }
    if (customerName == null) {
      throw StateError('OrderModel.fromMap: "customerName" is required');
    }
    if (customerEmail == null) {
      throw StateError('OrderModel.fromMap: "customerEmail" is required');
    }
    if (createdAt == null) {
      throw StateError('OrderModel.fromMap: "createdAt" is required');
    }

    return OrderModel(
      id: id,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: itemsList
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: total.toDouble(),
      status: OrderStatus.fromString(statusString),
      deliveryMethod: DeliveryMethod.fromString(deliveryMethodString),
      paymentMethod: PaymentMethod.fromString(paymentMethodString),
      deliveryAddress: map['deliveryAddress'] as String?,
      customerName: customerName,
      customerPhone: map['customerPhone'] as String?,
      customerEmail: customerEmail,
      createdAt: createdAt.toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      cancellationReason: map['cancellationReason'] as String?,
      unavailableItems:
          (map['unavailableItems'] as List?)?.cast<String>() ?? const [],
      estimatedPrepMinutes: estimatedPrepMinutes,
      lastMessageAt: map['lastMessageAt'] != null                  // ✅ NEW
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessageBy: map['lastMessageBy'] as String?,              // ✅ NEW
    );
  }

  OrderModel copyWith({
    String? userId,
    String? restaurantId,
    String? restaurantName,
    List<OrderItem>? items,
    double? total,
    int? estimatedPrepMinutes,
    OrderStatus? status,
    DeliveryMethod? deliveryMethod,
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    List<String>? unavailableItems,
    DateTime? lastMessageAt,          // ✅ NEW
    String? lastMessageBy,            // ✅ NEW
  }) {
    return OrderModel(
      id: id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unavailableItems: unavailableItems ?? this.unavailableItems,
      estimatedPrepMinutes: estimatedPrepMinutes ?? this.estimatedPrepMinutes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,          // ✅ NEW
      lastMessageBy: lastMessageBy ?? this.lastMessageBy,          // ✅ NEW
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel &&
        other.id == id &&
        other.userId == userId &&
        other.restaurantId == restaurantId &&
        other.restaurantName == restaurantName &&
        other.items == items &&
        other.total == total &&
        other.estimatedPrepMinutes == estimatedPrepMinutes &&
        other.status == status &&
        other.deliveryMethod == deliveryMethod &&
        other.paymentMethod == paymentMethod &&
        other.deliveryAddress == deliveryAddress &&
        other.customerName == customerName &&
        other.customerPhone == customerPhone &&
        other.customerEmail == customerEmail &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.cancellationReason == cancellationReason &&
        other.lastMessageAt == lastMessageAt &&                  // ✅ NEW
        other.lastMessageBy == lastMessageBy;                    // ✅ NEW
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      restaurantId,
      restaurantName,
      items,
      total,
      status,
      deliveryMethod,
      paymentMethod,
      deliveryAddress,
      customerName,
      customerPhone,
      customerEmail,
      createdAt,
      updatedAt,
      estimatedPrepMinutes,
      cancellationReason,
      lastMessageAt,                                              // ✅ NEW
      lastMessageBy,                                              // ✅ NEW
    );
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, userId: $userId, restaurantId: $restaurantId, '
        'restaurantName: $restaurantName, items: $items, total: $total, '
        'status: $status, deliveryMethod: $deliveryMethod, '
        'customerName: $customerName, createdAt: $createdAt)';
  }
}