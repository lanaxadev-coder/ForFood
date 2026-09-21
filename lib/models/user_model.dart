// ============================================================
// USER MODEL
// ============================================================
// Represents an authenticated user in the ForFood platform.
// This model maps directly to Firestore documents at:
//   /users/{userId}
//
// The `id` field is the Firebase Auth UID, ensuring a 1:1
// relationship between the Auth record and the Firestore document.
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forfood/service/auth/user_role.dart';  // ✅ ADD IMPORT

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final UserRole role;  // ✅ Add this

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.role,  // ✅ Required
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role.name,  // ✅ SAVE ROLE
    };
  }

  factory UserModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final fullName = map['fullName'] as String?;
    final email = map['email'] as String?;
    final createdAt = map['createdAt'] as Timestamp?;

    if (fullName == null) {
      throw StateError('UserModel.fromMap: "fullName" is required');
    }
    if (email == null) {
      throw StateError('UserModel.fromMap: "email" is required');
    }
    if (createdAt == null) {
      throw StateError('UserModel.fromMap: "createdAt" is required');
    }

    // ✅ READ ROLE
    final roleName = map['role'] as String?;
    final role = roleName == 'restaurant'
        ? UserRole.restaurant
        : UserRole.user;

    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phoneNumber: map['phoneNumber'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: createdAt.toDate(),
      role: role,  // ✅ SET ROLE
    );
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    UserRole? role,  // ✅ ADD
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,  // ✅ ADD
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.profileImageUrl == profileImageUrl &&
        other.createdAt == createdAt &&
        other.role == role;  // ✅ ADD
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      email,
      phoneNumber,
      profileImageUrl,
      createdAt,
      role,  // ✅ ADD
    );
  }

  @override
  String toString() {
    return 'UserModel(\n'
        '  id: $id,\n'
        '  fullName: $fullName,\n'
        '  email: $email,\n'
        '  phoneNumber: $phoneNumber,\n'
        '  profileImageUrl: $profileImageUrl,\n'
        '  createdAt: $createdAt,\n'
        '  role: $role,\n'  // ✅ ADD
        ')';
  }
}