// ============================================================
// RESTAURANT MODEL
// ============================================================
// Represents a restaurant profile in the ForFood platform.
// This model maps directly to Firestore documents at:
//   /restaurants/{restaurantId}
//
// Includes geolocation fields (latitude, longitude, geohash) for
// budget-first spatial search queries. The geohash enables
// efficient geo-bounding-box queries in Firestore.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a restaurant on the ForFood platform.
///
/// This class is immutable. Use [copyWith] to create modified
/// instances when updating restaurant data.
class RestaurantModel {
  /// Firestore document ID for this restaurant.
  final String id;

  /// Firebase Auth UID of the restaurant owner.
  /// Used for write-permission checks in Firestore security rules.
  final String ownerId;

  /// Restaurant's display name (e.g., "Pizza Rapide").
  final String name;

  /// Restaurant's description shown on the detail screen.
  final String description;

  /// Full street address (e.g., "321 East 14th Street, Manhattan, NY").
  final String address;

  /// Geographic latitude coordinate for spatial queries.
  final double latitude;

  /// Geographic longitude coordinate for spatial queries.
  final double longitude;

  /// Geohash string computed from [latitude] and [longitude].
  /// Used for Firestore geo-bounding-box queries.
  final String geohash;

  /// Average rating across all reviews (0.0 to 5.0).
  final double rating;

  /// Number of reviews contributing to [rating].
  final int ratingCount;

  /// URL to the restaurant's profile photo stored in Firebase Storage.
  /// Nullable — restaurants without a photo have no URL.
  final String? profileImageUrl;

  /// Whether the restaurant accepts delivery orders.
  /// Controlled by the delivery toggle on the restaurant home screen.
  final bool isDeliveryEnabled;

  /// Whether the restaurant has an active subscription.
  /// Gates access to the restaurant dashboard via RevenueCat entitlement.
  final bool subscriptionActive;

  /// Expiry date of the restaurant's subscription.
  /// Nullable — free trial or inactive subscriptions have no expiry.
  final DateTime? subscriptionExpiry;

  final bool isFeatured; // ✅ ADDED — paid placement flag
    /// Number of times users viewed this restaurant.
  final int views;


    final String? phoneNumber;  // ✅ ADD THIS


  /// Timestamp of when the restaurant account was created.
  final DateTime createdAt;

  /// Creates a new [RestaurantModel] instance.
  const RestaurantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.rating,
    required this.ratingCount,
    this.profileImageUrl,
    required this.isDeliveryEnabled,
    required this.subscriptionActive,
    this.subscriptionExpiry,
        required this.isFeatured, // ✅ ADDED
    required this.views,
        this.phoneNumber,  // ✅ ADD THIS

    required this.createdAt,
  });

  // ============================================================
  // FIRESTORE CONVERSION
  // ============================================================

  /// Converts this [RestaurantModel] to a Firestore-compatible map.
  ///
  /// The `id` field is excluded because it serves as the document ID.
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'rating': rating,
            'phoneNumber': phoneNumber,  // ✅ ADD THIS

      'ratingCount': ratingCount,
      'profileImageUrl': profileImageUrl,
      'isDeliveryEnabled': isDeliveryEnabled,
      'subscriptionActive': subscriptionActive,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
                'isFeatured': isFeatured, // ✅ ADDED
              'views': views,

      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [RestaurantModel] from a Firestore document.
  ///
  /// [id] is passed separately because it's the document ID,
  /// not a field within the document.
  ///
  /// Throws [StateError] if required fields are missing from [map].
  factory RestaurantModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    // Required fields — throw if missing
    final ownerId = map['ownerId'] as String?;
    final name = map['name'] as String?;
    final description = map['description'] as String?;
    final address = map['address'] as String?;
    final latitude = map['latitude'] as num?;
    final longitude = map['longitude'] as num?;
    final geohash = map['geohash'] as String?;
    final rating = map['rating'] as num?;
    final ratingCount = map['ratingCount'] as int?;
    final isDeliveryEnabled = map['isDeliveryEnabled'] as bool?;
    final subscriptionActive = map['subscriptionActive'] as bool?;
    final createdAt = map['createdAt'] as Timestamp?;

    if (ownerId == null) {
      throw StateError('RestaurantModel.fromMap: "ownerId" is required');
    }
    if (name == null) {
      throw StateError('RestaurantModel.fromMap: "name" is required');
    }
    if (address == null) {
      throw StateError('RestaurantModel.fromMap: "address" is required');
    }
    if (latitude == null) {
      throw StateError('RestaurantModel.fromMap: "latitude" is required');
    }
    if (longitude == null) {
      throw StateError('RestaurantModel.fromMap: "longitude" is required');
    }
    if (geohash == null) {
      throw StateError('RestaurantModel.fromMap: "geohash" is required');
    }
    if (rating == null) {
      throw StateError('RestaurantModel.fromMap: "rating" is required');
    }
    if (ratingCount == null) {
      throw StateError('RestaurantModel.fromMap: "ratingCount" is required');
    }
    if (isDeliveryEnabled == null) {
      throw StateError(
          'RestaurantModel.fromMap: "isDeliveryEnabled" is required');
    }
    if (subscriptionActive == null) {
      throw StateError(
          'RestaurantModel.fromMap: "subscriptionActive" is required');
    }
    if (createdAt == null) {
      throw StateError('RestaurantModel.fromMap: "createdAt" is required');
    }

    return RestaurantModel(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description ?? '',
      address: address,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      geohash: geohash,
      rating: rating.toDouble(),
      ratingCount: ratingCount,
      profileImageUrl: map['profileImageUrl'] as String?,
      isDeliveryEnabled: isDeliveryEnabled,
      subscriptionActive: subscriptionActive,
      subscriptionExpiry: map['subscriptionExpiry'] != null
          ? (map['subscriptionExpiry'] as Timestamp).toDate()
          : null,
     isFeatured: map['isFeatured'] as bool? ?? false, // ✅ ADDED
         views: map['views'] as int? ?? 0,
           phoneNumber: map['phoneNumber'] as String?,  // ✅ ADD THIS

      createdAt: createdAt.toDate(),
    );
  }

  // ============================================================
  // IMMUTABILITY SUPPORT
  // ============================================================

  /// Returns a copy of this [RestaurantModel] with the specified fields replaced.
  ///
  /// Unspecified fields remain unchanged.
  RestaurantModel copyWith({
    String? ownerId,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? geohash,
    double? rating,
    int? ratingCount,
    String? profileImageUrl,
    bool? isDeliveryEnabled,
    bool? subscriptionActive,
    DateTime? subscriptionExpiry,
    bool? isFeatured, // ✅ ADDED
       int? views,
      String? phoneNumber,  // ✅ ADD THIS

    DateTime? createdAt,

  }) {
    return RestaurantModel(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isFeatured: isFeatured ?? this.isFeatured, // ✅ ADDED

            views: views ?? this.views,
         phoneNumber: phoneNumber ?? this.phoneNumber,  // ✅ ADD THIS

      createdAt: createdAt ?? this.createdAt,
      
    );
  }

  // ============================================================
  // EQUALITY & HASHING
  // ============================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RestaurantModel &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.description == description &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.geohash == geohash &&
        other.rating == rating &&
        other.ratingCount == ratingCount &&
        other.profileImageUrl == profileImageUrl &&
        other.isDeliveryEnabled == isDeliveryEnabled &&
        other.subscriptionActive == subscriptionActive &&
        other.subscriptionExpiry == subscriptionExpiry &&
        other.isFeatured == isFeatured &&        // ✅ ADDED
        other.views == views &&     
              other.phoneNumber == phoneNumber &&  // ✅ ADDED
     
        other.createdAt == createdAt;
        
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      name,
      description,
      address,
      latitude,
      longitude,
      geohash,
      rating,
      ratingCount,
      profileImageUrl,
      isDeliveryEnabled,
      subscriptionActive,
      subscriptionExpiry,
        isFeatured, 
            phoneNumber,  // ✅ ADDED
       // ✅ ADDED
      views,     
      createdAt,
    );
  }

  // ============================================================
  // DEBUGGING
  // ============================================================

  @override
  String toString() {
    return 'RestaurantModel(\n'
        '  id: $id,\n'
        '  ownerId: $ownerId,\n'
        '  name: $name,\n'
        '  description: $description,\n'
        '  address: $address,\n'
        '  latitude: $latitude,\n'
        '  longitude: $longitude,\n'
        '  geohash: $geohash,\n'
        '  rating: $rating,\n'
        '  ratingCount: $ratingCount,\n'
        '  profileImageUrl: $profileImageUrl,\n'
        '  isDeliveryEnabled: $isDeliveryEnabled,\n'
        '  subscriptionActive: $subscriptionActive,\n'
        '  subscriptionExpiry: $subscriptionExpiry,\n'
         '  isFeatured: $isFeatured,\n'        // ✅ ADDED
        '  views: $views,\n' 
              '  phoneNumber: $phoneNumber,\n'  // ✅ ADDED

        '  createdAt: $createdAt,\n'

        ')';
  }
}