// ============================================================
// USER ROLE ENUM
// ============================================================
// Determines which side of the ForFood marketplace
// the authenticated user belongs to.
// ============================================================

/// Represents the role of an authenticated user.
enum UserRole {
  /// Regular user who searches for food and places orders.
  user,

  /// Restaurant owner who manages their restaurant and fulfills orders.
  restaurant;
}