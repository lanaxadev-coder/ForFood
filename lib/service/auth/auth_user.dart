// ============================================================
// AUTH USER MODEL
// ============================================================
// Lightweight representation of the authenticated user.
//
// This is different from [UserModel] because it includes
// the user's role (user vs restaurant) and does not include
// Firestore-specific data like createdAt.
// ============================================================

import 'package:forfood/service/auth/user_role.dart';

/// Represents the currently authenticated user.
class AuthUser {
  /// Firebase Auth UID.
  final String id;

  /// User's full name.
  final String fullName;

  /// User's email address.
  final String email;

  /// User's phone number (nullable).
  final String? phoneNumber;

  /// URL to user's profile photo (nullable).
  final String? profileImageUrl;

  /// Whether this user is a regular user or a restaurant owner.
  final UserRole role;

  /// Creates a new [AuthUser] instance.
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
  });

  /// Returns true if this user is a restaurant owner.
  bool get isRestaurant => role == UserRole.restaurant;

  /// Returns true if this user is a regular user.
  bool get isUser => role == UserRole.user;

  @override
  String toString() {
    return 'AuthUser(id: $id, fullName: $fullName, email: $email, role: $role)';
  }
}