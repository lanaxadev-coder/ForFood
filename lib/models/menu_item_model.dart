// ============================================================
// MENU ITEM MODEL
// ============================================================
// Represents a single menu item belonging to a restaurant.
// This model maps directly to Firestore documents at:
//   /restaurants/{restaurantId}/menu_items/{menuItemId}
//
// The `orderCount` field tracks total orders for this item and
// is incremented via Firestore's `FieldValue.increment(1)` when
// an order containing this item is placed. This powers the
// "High Demand" sorting and "+1k" badges in the UI.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a menu item on the ForFood platform.
///
/// This class is immutable. Use [copyWith] to create modified
/// instances when updating menu item data.
class MenuItemModel {
  /// Firestore document ID for this menu item.
  final String id;

  /// Firestore document ID of the parent restaurant.
  /// Used for querying and security rule enforcement.
  final String restaurantId;

  /// Menu item's display name (e.g., "Double Cheese Burger").
  final String name;

  /// Price in USD (e.g., 8.00 for $8.00).
  final double price;

  /// Optional longer description of the menu item.
  /// Nullable — short descriptions may be omitted.
  final String? description;

  /// URL to the menu item's photo stored in Firebase Storage.
  /// Nullable — items without a photo have no URL.
  final String? imageUrl;

  /// Total number of times this item has been ordered.
  /// Used for "High Demand" sorting. Defaults to 0.
  final int orderCount;

  /// Timestamp of when the menu item was created.
  final DateTime createdAt;

  /// Creates a new [MenuItemModel] instance.
  const MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    required this.orderCount,
    required this.createdAt,
  });

  // ============================================================
  // FIRESTORE CONVERSION
  // ============================================================

  /// Converts this [MenuItemModel] to a Firestore-compatible map.
  ///
  /// The `id` field is excluded because it serves as the document ID.
  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'orderCount': orderCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [MenuItemModel] from a Firestore document.
  ///
  /// [id] is passed separately because it's the document ID,
  /// not a field within the document.
  ///
  /// Throws [StateError] if required fields are missing from [map].
  factory MenuItemModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    // Required fields — throw if missing
    final restaurantId = map['restaurantId'] as String?;
    final name = map['name'] as String?;
    final price = map['price'] as num?;
    final orderCount = map['orderCount'] as int?;
    final createdAt = map['createdAt'] as Timestamp?;

    if (restaurantId == null) {
      throw StateError('MenuItemModel.fromMap: "restaurantId" is required');
    }
    if (name == null) {
      throw StateError('MenuItemModel.fromMap: "name" is required');
    }
    if (price == null) {
      throw StateError('MenuItemModel.fromMap: "price" is required');
    }
    if (orderCount == null) {
      throw StateError('MenuItemModel.fromMap: "orderCount" is required');
    }
    if (createdAt == null) {
      throw StateError('MenuItemModel.fromMap: "createdAt" is required');
    }

    return MenuItemModel(
      id: id,
      restaurantId: restaurantId,
      name: name,
      price: price.toDouble(),
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      orderCount: orderCount,
      createdAt: createdAt.toDate(),
    );
  }

  // ============================================================
  // IMMUTABILITY SUPPORT
  // ============================================================

  /// Returns a copy of this [MenuItemModel] with the specified fields replaced.
  ///
  /// Unspecified fields remain unchanged.
  MenuItemModel copyWith({
    String? restaurantId,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    int? orderCount,
    DateTime? createdAt,
  }) {
    return MenuItemModel(
      id: id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ============================================================
  // EQUALITY & HASHING
  // ============================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItemModel &&
        other.id == id &&
        other.restaurantId == restaurantId &&
        other.name == name &&
        other.price == price &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.orderCount == orderCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      restaurantId,
      name,
      price,
      description,
      imageUrl,
      orderCount,
      createdAt,
    );
  }

  // ============================================================
  // DEBUGGING
  // ============================================================

  @override
  String toString() {
    return 'MenuItemModel(\n'
        '  id: $id,\n'
        '  restaurantId: $restaurantId,\n'
        '  name: $name,\n'
        '  price: $price,\n'
        '  description: $description,\n'
        '  imageUrl: $imageUrl,\n'
        '  orderCount: $orderCount,\n'
        '  createdAt: $createdAt,\n'
        ')';
  }
}