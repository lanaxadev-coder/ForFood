// ============================================================
// DOMAIN EXCEPTIONS
// ============================================================
// Typed exceptions for all domain-level error scenarios.
//
// These exceptions are thrown by providers and services when
// a business rule is violated or a Firebase operation fails.
// They are caught by BLoCs and mapped to UI-friendly error
// messages without exposing raw FirebaseException details
// to the presentation layer.
//
// Every exception extends [DomainException], which provides
// a common base with a user-friendly [message] and optional
// machine-readable [code].
// ============================================================

/// Base exception for all domain-level errors in ForFood.
///
/// Provides a consistent structure for error handling across
/// all services and BLoCs.
abstract class DomainException implements Exception {
  /// User-friendly error message that can be displayed directly
  /// in the UI or mapped to a localized string.
  final String message;

  /// Optional machine-readable error code for programmatic handling.
  final String? code;

  /// Creates a new [DomainException] with the given [message]
  /// and optional [code].
  const DomainException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';
}

// ============================================================
// AUTH EXCEPTIONS
// ============================================================

/// Thrown when user authentication fails (wrong email/password).
class AuthenticationException extends DomainException {
  const AuthenticationException(super.message);
}

/// Thrown when a user attempts to sign up with an email that
/// is already registered.
class EmailAlreadyInUseException extends DomainException {
  const EmailAlreadyInUseException()
      : super('An account with this email already exists');
}

/// Thrown when a user attempts to log in with invalid credentials.
class InvalidCredentialsException extends DomainException {
  const InvalidCredentialsException()
      : super('Invalid email or password. Please try again.');
}

/// Thrown when a user attempts to perform an action that requires
/// email verification but has not yet verified their email.
class EmailNotVerifiedException extends DomainException {
  const EmailNotVerifiedException()
      : super('Email verification is required before proceeding');
}


/// Thrown when user tries to login but hasn't completed signup.
class SignupIncompleteException extends DomainException {
  const SignupIncompleteException()
      : super('Please complete your signup first. Use the Sign Up screen.');
}

/// Thrown when user account deletion fails.
class AccountDeletionException extends DomainException {
  const AccountDeletionException(super.message);
}

// ============================================================
// USER EXCEPTIONS
// ============================================================

/// Thrown when a user document is not found in Firestore.
class UserNotFoundException extends DomainException {
  const UserNotFoundException(String userId)
      : super('User with ID $userId not found');
}

// ============================================================
// RESTAURANT EXCEPTIONS
// ============================================================

/// Thrown when a restaurant document is not found in Firestore.
class RestaurantNotFoundException extends DomainException {
  const RestaurantNotFoundException(String restaurantId)
      : super('Restaurant with ID $restaurantId not found');
}

/// Thrown when a non-restaurant-owner attempts to modify a
/// restaurant profile.
class RestaurantPermissionException extends DomainException {
  const RestaurantPermissionException()
      : super('You do not have permission to modify this restaurant');
}

/// Thrown when a restaurant's subscription has expired or is inactive.
class SubscriptionInactiveException extends DomainException {
  const SubscriptionInactiveException()
      : super('Active subscription required to access this feature');
}

// ============================================================
// MENU ITEM EXCEPTIONS
// ============================================================

/// Thrown when a menu item document is not found in Firestore.
class MenuItemNotFoundException extends DomainException {
  const MenuItemNotFoundException(String menuItemId)
      : super('Menu item with ID $menuItemId not found');
}

/// Thrown when inventory is insufficient for an order.
class InsufficientInventoryException extends DomainException {
  const InsufficientInventoryException(
    String itemName,
    int requested,
    int available,
  ) : super(
          'Insufficient inventory for $itemName: '
          'requested $requested, available $available',
        );
}

// ============================================================
// SEARCH EXCEPTIONS
// ============================================================

/// Thrown when the price filter is outside acceptable bounds.
class PriceFilterOutOfRangeException extends DomainException {
  const PriceFilterOutOfRangeException()
      : super('Price filter must be greater than 0 and less than \$1000');
}

/// Thrown when the user's location cannot be determined for
/// distance-based search.
class LocationUnavailableException extends DomainException {
  const LocationUnavailableException()
      : super('Unable to determine your location. Please enable location services.');
}

// ============================================================
// CART EXCEPTIONS
// ============================================================

/// Thrown when user attempts to add items from multiple restaurants
/// to the same cart. ForFood enforces single-restaurant carts.
class MultiRestaurantCartException extends DomainException {
  const MultiRestaurantCartException()
      : super(
          'Cannot add items from multiple restaurants to the same cart. '
          'Please clear your cart first.',
        );
}

/// Thrown when user attempts to add an unavailable menu item to cart.
class ItemUnavailableException extends DomainException {
  const ItemUnavailableException(String itemName)
      : super('$itemName is currently unavailable');
}

// ============================================================
// ORDER EXCEPTIONS
// ============================================================

/// Thrown when an order document is not found in Firestore.
class OrderNotFoundException extends DomainException {
  const OrderNotFoundException(String orderId)
      : super('Order with ID $orderId not found');
}

/// Thrown when an order state transition is invalid.
/// Example: attempting to cancel a completed order.
class InvalidOrderStateTransitionException extends DomainException {
  const InvalidOrderStateTransitionException(
    String currentState,
    String targetState,
  ) : super('Cannot transition order from $currentState to $targetState');
}

/// Thrown when user attempts to place an order with an empty cart.
class EmptyCartException extends DomainException {
  const EmptyCartException()
      : super('Your cart is empty. Add items before placing an order.');
}

// ============================================================
// FIRESTORE / NETWORK EXCEPTIONS
// ============================================================

/// Thrown when a Firestore write fails due to security rules.
class PermissionDeniedException extends DomainException {
  const PermissionDeniedException()
      : super('You do not have permission to perform this action');
}

/// Thrown when network connectivity is unavailable.
class NetworkUnavailableException extends DomainException {
  const NetworkUnavailableException()
      : super(
          'Network connection unavailable. '
          'Please check your connection and try again.',
        );
}

/// Thrown when a Firestore operation times out.
class FirestoreTimeoutException extends DomainException {
  const FirestoreTimeoutException()
      : super('The operation timed out. Please try again.');
}

/// Thrown when a Firestore operation fails for an unexpected reason.
class FirestoreOperationException extends DomainException {
  const FirestoreOperationException(String message)
      : super('Database operation failed: $message');
}