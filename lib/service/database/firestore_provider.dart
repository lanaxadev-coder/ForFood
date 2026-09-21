// ============================================================
// FIRESTORE PROVIDER — COMPLETE CORRECTED VERSION
// ============================================================
// Central data access layer for all Firestore operations.
//
// This provider abstracts raw Firestore calls behind clean,
// typed methods. It converts Firestore documents to domain
// models and throws typed DomainExceptions on failure.
//
// All BLoCs and services interact with this provider —
// never with Firestore directly.
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forfood/models/address_model.dart';
import 'package:forfood/models/chat_message_model.dart';
import 'package:forfood/models/review_model.dart';
import 'package:flutter/foundation.dart';  // for debugPrint

import 'package:forfood/models/user_model.dart';
import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/models/menu_item_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/models/notification_model.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:http/http.dart' as http;

/// Firestore collection name constants.
class FirestoreCollections {
  static const String users = 'users';
  static const String restaurants = 'restaurants';
  static const String menuItems = 'menu_items';
  static const String gallery = 'gallery';
  static const String orders = 'orders';
  static const String notifications = 'notifications';
}

/// Provides typed access to Firestore data.
///
/// All methods convert between Firestore documents and domain
/// models, and throw [DomainException] subclasses on error.
class FirestoreProvider {
  final FirebaseFirestore _firestore;
  static const String _imgbbApiKey = '7e094da09d19bcca58d901b78b8e8a11';

  /// Creates a new [FirestoreProvider] instance.
  ///
  /// [firestore] is injected for testability.
  FirestoreProvider({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // USER OPERATIONS
  // ============================================================

  /// Creates a new user document in Firestore.
  Future<UserModel> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.id)
          .set(user.toMap());
      return user;
    } on FirebaseException catch (e) {
      throw FirestoreOperationException('Failed to create user: ${e.message}');
    }
  }

  /// Fetches a user document by Firebase Auth UID.
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw UserNotFoundException(userId);
      }

      return UserModel.fromMap(
        id: doc.id,
        map: doc.data()!,
      );
    } on UserNotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      throw FirestoreOperationException('Failed to fetch user: ${e.message}');
    }
  }

  /// Updates an existing user document.
  /// ✅ FIXED: Uses set() with merge to CREATE missing fields like 'role'
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.id)
          .set(
            user.toMap(),
            SetOptions(merge: true),  // ✅ Creates 'role' if missing!
          );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException('Failed to update user: ${e.message}');
    }
  }

  /// Deletes a user document from Firestore.
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .delete();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException('Failed to delete user: ${e.message}');
    }
  }







  // add an image 


  
Future<String> uploadImage({
  required File file,
  required String path,
}) async {
  try {
    // Read the file bytes
    final bytes = await file.readAsBytes();

    // Encode to base64 (ImgBB requires this)
    final base64Image = base64Encode(bytes);

    // Build the request
    final url = Uri.parse(
      'https://api.imgbb.com/1/upload?key=$_imgbbApiKey',
    );

    final response = await http.post(
      url,
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode != 200) {
      throw FirestoreOperationException(
        'ImgBB upload failed: ${response.statusCode} ${response.body}',
      );
    }

    // Parse response
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final imageUrl = data['data']?['url'] as String?;

    if (imageUrl == null) {
      throw const FirestoreOperationException('ImgBB returned no URL');
    }

    debugPrint('✅ ImgBB upload: $imageUrl');
    return imageUrl;
  } catch (e) {
    if (e is FirestoreOperationException) rethrow;
    throw FirestoreOperationException('Failed to upload image: $e');
  }
}

  // ============================================================
  // RESTAURANT OPERATIONS
  // ============================================================

  /// Creates a new restaurant document in Firestore.
  Future<RestaurantModel> createRestaurant(RestaurantModel restaurant) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.restaurants)
          .add(restaurant.toMap());

      return RestaurantModel(
        id: docRef.id,
        ownerId: restaurant.ownerId,
        name: restaurant.name,
        description: restaurant.description,
        address: restaurant.address,
        latitude: restaurant.latitude,
        longitude: restaurant.longitude,
        geohash: restaurant.geohash,
        rating: restaurant.rating,
        ratingCount: restaurant.ratingCount,
        profileImageUrl: restaurant.profileImageUrl,
        isDeliveryEnabled: restaurant.isDeliveryEnabled,
        subscriptionActive: restaurant.subscriptionActive,
        subscriptionExpiry: restaurant.subscriptionExpiry,
        createdAt: restaurant.createdAt,
        isFeatured: restaurant.isFeatured,
        views: restaurant.views,
          phoneNumber: restaurant.phoneNumber,          // ✅ ADD THIS

      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to create restaurant: ${e.message}');
    }
  }

  /// Fetches a restaurant document by ID.
  Future<RestaurantModel> getRestaurantById(String restaurantId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .get();

      if (!doc.exists) {
        throw RestaurantNotFoundException(restaurantId);
      }

      return RestaurantModel.fromMap(
        id: doc.id,
        map: doc.data()!,
      );
    } on RestaurantNotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to fetch restaurant: ${e.message}');
    }
  }

  /// Fetches a restaurant document by owner's Firebase Auth UID.
  Future<RestaurantModel?> getRestaurantByOwnerId(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.restaurants)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return RestaurantModel.fromMap(
        id: doc.id,
        map: doc.data(),
      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to fetch restaurant by owner: ${e.message}');
    }
  }

  /// Updates an existing restaurant document.
  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    try {
      await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurant.id)
          .set(
            restaurant.toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to update restaurant: ${e.message}');
    }
  }

  /// Streams a restaurant document in real-time.
  Stream<RestaurantModel?> streamRestaurantById(String restaurantId) {
    return _firestore
        .collection(FirestoreCollections.restaurants)
        .doc(restaurantId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return RestaurantModel.fromMap(
        id: doc.id,
        map: doc.data()!,
      );
    });
  }

  // ============================================================
  // MENU ITEM OPERATIONS
  // ============================================================

  /// Creates a new menu item under a restaurant.
  Future<MenuItemModel> createMenuItem(MenuItemModel menuItem) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(menuItem.restaurantId)
          .collection(FirestoreCollections.menuItems)
          .add(menuItem.toMap());

      return MenuItemModel(
        id: docRef.id,
        restaurantId: menuItem.restaurantId,
        name: menuItem.name,
        price: menuItem.price,
        description: menuItem.description,
        imageUrl: menuItem.imageUrl,
        orderCount: menuItem.orderCount,
        createdAt: menuItem.createdAt,
      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to create menu item: ${e.message}');
    }
  }

  /// Fetches all menu items for a restaurant.
  Future<List<MenuItemModel>> getMenuItemsByRestaurantId(
      String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.menuItems)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => MenuItemModel.fromMap(
                id: doc.id,
                map: doc.data(),
              ))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to fetch menu items: ${e.message}');
    }
  }

  /// Streams all menu items for a restaurant in real-time.
  Stream<List<MenuItemModel>> streamMenuItemsByRestaurantId(
      String restaurantId) {
    return _firestore
        .collection(FirestoreCollections.restaurants)
        .doc(restaurantId)
        .collection(FirestoreCollections.menuItems)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItemModel.fromMap(
                id: doc.id,
                map: doc.data(),
              ))
          .toList();
    });
  }

  /// Updates an existing menu item.
  Future<void> updateMenuItem(MenuItemModel menuItem) async {
    try {
      await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(menuItem.restaurantId)
          .collection(FirestoreCollections.menuItems)
          .doc(menuItem.id)
          .set(
            menuItem.toMap(),
            SetOptions(merge: true),
          );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to update menu item: ${e.message}');
    }
  }

  /// Deletes a menu item.
  Future<void> deleteMenuItem({
    required String restaurantId,
    required String menuItemId,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.menuItems)
          .doc(menuItemId)
          .delete();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to delete menu item: ${e.message}');
    }
  }

  /// Increments the order count for a menu item.
  Future<void> incrementMenuItemOrderCount({
    required String restaurantId,
    required String menuItemId,
    int increment = 1,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.menuItems)
          .doc(menuItemId)
          .update({
        'orderCount': FieldValue.increment(increment),
      });
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to increment menu item order count: ${e.message}');
    }
  }

  // ============================================================
  // ORDER OPERATIONS
  // ============================================================

  /// Creates a new order document in Firestore.
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.orders)
          .add(order.toMap());

      for (final item in order.items) {
        await incrementMenuItemOrderCount(
          restaurantId: order.restaurantId,
          menuItemId: item.menuItemId,
          increment: item.quantity,
        );
      }

      return OrderModel(
        id: docRef.id,
        userId: order.userId,
        restaurantId: order.restaurantId,
        restaurantName: order.restaurantName,
        items: order.items,
        total: order.total,
        status: order.status,
        deliveryMethod: order.deliveryMethod,
        paymentMethod: order.paymentMethod,
        deliveryAddress: order.deliveryAddress,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerEmail: order.customerEmail,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        estimatedPrepMinutes: order.estimatedPrepMinutes,
        cancellationReason: order.cancellationReason,
          unavailableItems: order.unavailableItems,     // ✅ ADD THIS

      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException('Failed to create order: ${e.message}');
    }
  }

  /// Fetches an order document by ID.
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.orders)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        throw OrderNotFoundException(orderId);
      }

      return OrderModel.fromMap(
        id: doc.id,
        map: doc.data()!,
      );
    } on OrderNotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      throw FirestoreOperationException('Failed to fetch order: ${e.message}');
    }
  }

  /// Streams all orders for a specific user in real-time.
    /// Streams all orders for a specific user in real-time.
  Stream<List<OrderModel>> streamOrdersByUserId(String userId) {
    return _firestore
        .collection(FirestoreCollections.orders)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(
                id: doc.id,
                map: doc.data(),
              ))
          .toList();

      // Sort newest first — no Firestore composite index needed
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }
  /// Streams all orders for a specific restaurant in real-time.
   /// Streams all orders for a specific restaurant in real-time.
  Stream<List<OrderModel>> streamOrdersByRestaurantId(String restaurantId) {
    return _firestore
        .collection(FirestoreCollections.orders)
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(
                id: doc.id,
                map: doc.data(),
              ))
          .toList();

      // Sort newest first — no Firestore composite index needed
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Updates an order's status.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? cancellationReason,
    int? estimatedPrepMinutes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (cancellationReason != null) {
        updates['cancellationReason'] = cancellationReason;
      }

      if (estimatedPrepMinutes != null) {
        updates['estimatedPrepMinutes'] = estimatedPrepMinutes;
      }

      await _firestore
          .collection(FirestoreCollections.orders)
          .doc(orderId)
          .update(updates);
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to update order status: ${e.message}');
    }
  }

  // ============================================================
  // GALLERY OPERATIONS
  // ============================================================

  /// Adds a gallery image URL to a restaurant's gallery subcollection.
  Future<void> addGalleryImage({
    required String restaurantId,
    required String imageUrl,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.gallery)
          .add({
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to add gallery image: ${e.message}');
    }
  }

  /// Streams gallery images for a restaurant in real-time.
  Stream<List<String>> streamGalleryImagesByRestaurantId(String restaurantId) {
    return _firestore
        .collection(FirestoreCollections.restaurants)
        .doc(restaurantId)
        .collection(FirestoreCollections.gallery)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['imageUrl'] as String)
          .toList();
    });
  }

  // ============================================================
  // SEARCH OPERATIONS
  // ============================================================

  /// Searches for restaurants within a geohash bounding box.
 Future<List<RestaurantModel>> searchRestaurantsByGeohashPrefix(
    String geohashPrefix) async {
  try {
    debugPrint('🔍 [FIRESTORE] query geohash prefix="$geohashPrefix"');
    debugPrint('🔍 [FIRESTORE] range: "$geohashPrefix" → "${geohashPrefix}\uf8ff"');

    final querySnapshot = await _firestore
        .collection(FirestoreCollections.restaurants)
        .where('geohash', isGreaterThanOrEqualTo: geohashPrefix)
        .where('geohash', isLessThanOrEqualTo: '$geohashPrefix\uf8ff')
        .get();

    debugPrint('🔍 [FIRESTORE] raw docs: ${querySnapshot.docs.length}');
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      debugPrint('🔍 [FIRESTORE]   id=${doc.id} '
          'name=${data['name']} geohash=${data['geohash']}');
    }

    return querySnapshot.docs
        .map((doc) => RestaurantModel.fromMap(
              id: doc.id,
              map: doc.data(),
            ))
        .toList();
  } on FirebaseException catch (e) {
    debugPrint('❌ [FIRESTORE] query failed: ${e.message} code=${e.code}');
    throw FirestoreOperationException(
        'Failed to search restaurants: ${e.message}');
  }
}

  // ============================================================
  // NOTIFICATION OPERATIONS
  // ============================================================

  /// Creates a new notification document.
  Future<NotificationModel> createNotification(
      NotificationModel notification) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.notifications)
          .add(notification.toMap());

      return NotificationModel(
        id: docRef.id,
        recipientId: notification.recipientId,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        orderId: notification.orderId,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to create notification: ${e.message}');
    }
  }

  /// Streams notifications for a recipient in real-time.
 Stream<List<NotificationModel>> streamNotificationsByRecipientId(
    String recipientId) {
  return _firestore
      .collection(FirestoreCollections.notifications)
      .where('recipientId', isEqualTo: recipientId)
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();

    final notifications = snapshot.docs
      .map((doc) => NotificationModel.fromMap(
              id: doc.id,
              map: doc.data(),
            ))
        // 👈 Hide notifications whose deliverAt is in the future
        .where((n) => n.deliverAt == null || !n.deliverAt!.isAfter(now))
        .toList();

    // Sort newest first
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  });
}
  /// Marks a notification as read.
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.notifications)
          .doc(notificationId)
          .update({'isRead': true});
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to mark notification as read: ${e.message}');
    }
  }

  /// Marks all notifications for a recipient as read.
  Future<void> markAllNotificationsAsRead(String recipientId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.notifications)
          .where('recipientId', isEqualTo: recipientId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to mark all notifications as read: ${e.message}');
    }
  }

  /// Fetches all restaurants (limited).
  Future<List<RestaurantModel>> getAllRestaurants({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.restaurants)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => RestaurantModel.fromMap(
                id: doc.id,
                map: doc.data(),
              ))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to fetch restaurants: ${e.message}');
    }
  }

  // ============================================================
  // VIEWS OPERATIONS
  // ============================================================

  /// Increments the view count for a restaurant.
  Future<void> incrementRestaurantViews(String restaurantId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .update({'views': FieldValue.increment(1)});
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to increment views: ${e.message}');
    }
  }

  // ============================================================
  // REVIEW OPERATIONS
  // ============================================================

  /// Creates a new review.
  Future<ReviewModel> createReview(ReviewModel review) async {
    try {
      final docRef =
          await _firestore.collection('reviews').add(review.toMap());

      return ReviewModel(
        id: docRef.id,
        restaurantId: review.restaurantId,
        userId: review.userId,
        userName: review.userName,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to create review: ${e.message}');
    }
  }

  /// Updates restaurant rating after new review.
  Future<void> updateRestaurantRating({
    required String restaurantId,
    required int newRating,
  }) async {
    try {
      final restaurantRef = _firestore
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(restaurantRef);
        final data = snapshot.data()!;

        final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = data['ratingCount'] as int? ?? 0;

        final newCount = currentCount + 1;
        final updatedRating =
            ((currentRating * currentCount) + newRating) / newCount;

        transaction.update(restaurantRef, {
          'rating': updatedRating,
          'ratingCount': newCount,
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to update rating: ${e.message}');
    }
  }

/// Streams all reviews for a restaurant in real-time.
Stream<List<ReviewModel>> streamReviewsByRestaurantId(String restaurantId) {
  return _firestore
      .collection('reviews')
      .where('restaurantId', isEqualTo: restaurantId)
      .snapshots()
      .map((snapshot) {
    final reviews = snapshot.docs
        .map((doc) => ReviewModel.fromMap(
              id: doc.id,
              map: doc.data(),
            ))
        .toList();

    // Sort newest first — no Firestore composite index needed
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  });
}


// ============================================================
// CHAT / MESSAGES (per-order)
// ============================================================

/// Streams all chat messages for an order, oldest first.
Stream<List<ChatMessageModel>> streamOrderMessages(String orderId) {
  return _firestore
      .collection(FirestoreCollections.orders)
      .doc(orderId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromMap(
              id: doc.id,
              map: doc.data(),
            ))
        .toList();
  });
}

/// Sends a chat message on an order.
/// Sends a chat message on an order and notifies the other party.
/// Sends a chat message on an order and notifies the other party.
Future<void> sendOrderMessage(ChatMessageModel message) async {
  try {
    // 1. Write the message
    await _firestore
        .collection(FirestoreCollections.orders)
        .doc(message.orderId)
        .collection('messages')
        .add(message.toMap());


          await _firestore
        .collection(FirestoreCollections.orders)
        .doc(message.orderId)
        .update({
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageBy': message.sender.name,
    });

    // 2. Look up the order to figure out who to notify
    final orderDoc = await _firestore
        .collection(FirestoreCollections.orders)
        .doc(message.orderId)
        .get();

    if (!orderDoc.exists) return;
    final orderData = orderDoc.data();
    if (orderData == null) return;

    String? recipientId;

    if (message.sender == ChatSender.user) {
      // User → notify restaurant OWNER (auth UID, not restaurant doc ID)
      final restaurantId = orderData['restaurantId'] as String?;
      if (restaurantId == null || restaurantId.isEmpty) return;

      try {
        final restaurantDoc = await _firestore
            .collection(FirestoreCollections.restaurants)
            .doc(restaurantId)
            .get();

        if (!restaurantDoc.exists) return;
        recipientId = restaurantDoc.data()?['ownerId'] as String?;
      } catch (e) {
        debugPrint('CHAT: failed to resolve restaurant owner: $e');
        return;
      }
    } else {
      // Restaurant → notify user (userId IS the auth UID)
      recipientId = orderData['userId'] as String?;
    }

    if (recipientId == null || recipientId.isEmpty) return;

    // 3. Create the notification
    final preview = message.text.length > 60
        ? '${message.text.substring(0, 60)}…'
        : message.text;

    final notification = NotificationModel(
      id: '',
      recipientId: recipientId,
      type: NotificationType.chatMessage,
      title: NotificationType.chatMessage.title,
      message: preview,
      orderId: message.orderId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  } on FirebaseException catch (e) {
    throw FirestoreOperationException(
        'Failed to send message: ${e.message}');
  }
}
  // ============================================================
  // ADDRESS OPERATIONS
  // ============================================================

  /// Creates a new address for a user.
  Future<AddressModel> createAddress(AddressModel address) async {
    try {
      final docRef = await _firestore
          .collection(FirestoreCollections.users)
          .doc(address.userId)
          .collection('addresses')
          .add(address.toMap());

      return AddressModel(
        id: docRef.id,
        userId: address.userId,
        label: address.label,
        fullAddress: address.fullAddress,
        isDefault: address.isDefault,
        createdAt: address.createdAt,
      );
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to create address: ${e.message}');
    }
  }

  /// Streams addresses for a user.
  Stream<List<AddressModel>> streamAddressesByUserId(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection('addresses')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AddressModel.fromMap(
                id: doc.id,
                map: doc.data(),
              ))
          .toList();
    });
  }

  /// Deletes an address.
  Future<void> deleteAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to delete address: ${e.message}');
    }
  }
  /// Flags specific items on an order as unavailable.
  /// 
  /// 
  /// 
/// Called by the restaurant when they run out of an item mid-order.
Future<void> markItemsUnavailable({
  required String orderId,
  required List<String> menuItemIds,
}) async {
  try {
    await _firestore
        .collection(FirestoreCollections.orders)
        .doc(orderId)
        .update({
      'unavailableItems': FieldValue.arrayUnion(menuItemIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (e) {
    throw FirestoreOperationException(
        'Failed to mark items unavailable: ${e.message}');
  }
}

  /// Sets an address as default.
  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      batch.update(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userId)
            .collection('addresses')
            .doc(addressId),
        {'isDefault': true},
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreOperationException(
          'Failed to set default address: ${e.message}');
    }
  }
}