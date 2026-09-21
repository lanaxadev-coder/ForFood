// ============================================================
// ADDRESS MODEL
// ============================================================
// Represents a user's saved delivery address.
// Maps to Firestore at: /users/{userId}/addresses/{addressId}
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String label; // e.g., "My home", "Office"
  final String fullAddress;
  final bool isDefault;
  final DateTime createdAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullAddress,
    required this.isDefault,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'label': label,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AddressModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return AddressModel(
      id: id,
      userId: map['userId'] as String,
      label: map['label'] as String,
      fullAddress: map['fullAddress'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  AddressModel copyWith({
    String? label,
    String? fullAddress,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      userId: userId,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}