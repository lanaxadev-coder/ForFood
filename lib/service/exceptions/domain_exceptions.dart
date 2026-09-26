


// ============================================================
// DOMAIN EXCEPTIONS
// ============================================================
// Typed exceptions for all domain-level error scenarios.
//
// IMPORTANT: The string passed to `super(...)` is what the USER sees.
// Keep it plain English (or whichever language), no IDs, no codes,
// no "Firestore", no "Exception".
//
// For developer logging, use `debugPrint('❌ ...: $e')` at the catch site.
// ============================================================

/// Base exception for all domain-level errors in ForFood.
abstract class DomainException implements Exception {
  /// User-friendly error message shown in the UI.
  final String message;

  /// Optional machine-readable error code for programmatic handling.
  final String? code;

  const DomainException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';
}

// ============================================================
// AUTH EXCEPTIONS
// ============================================================

/// Generic auth failure.
class AuthenticationException extends DomainException {
  const AuthenticationException([super.message = 'Authentication failed. Please try again.']);
}

/// Email already registered.
class EmailAlreadyInUseException extends DomainException {
  const EmailAlreadyInUseException()
      : super('That email is already registered. Try logging in instead.');
}

/// Wrong email/password.
class InvalidCredentialsException extends DomainException {
  const InvalidCredentialsException()
      : super('Wrong email or password. Please try again.');
}

/// Email not verified yet.
class EmailNotVerifiedException extends DomainException {
  const EmailNotVerifiedException()
      : super('Please verify your email first — check your inbox.');
}

/// Signup not finished.
class SignupIncompleteException extends DomainException {
  const SignupIncompleteException()
      : super('Please finish signing up first.');
}

/// Account deletion failed.
class AccountDeletionException extends DomainException {
  const AccountDeletionException([super.message = 'Couldn\'t delete your account. Please try again.']);
}

// ============================================================
// USER EXCEPTIONS
// ============================================================

class UserNotFoundException extends DomainException {
  const UserNotFoundException(String userId)
      : super('We couldn\'t find your account. Please log in again.');
}

// ============================================================
// RESTAURANT EXCEPTIONS
// ============================================================

class RestaurantNotFoundException extends DomainException {
  const RestaurantNotFoundException(String restaurantId)
      : super('This restaurant is no longer available.');
}

class RestaurantPermissionException extends DomainException {
  const RestaurantPermissionException()
      : super('You don\'t have permission to do that.');
}

class SubscriptionInactiveException extends DomainException {
  const SubscriptionInactiveException()
      : super('An active subscription is required for this feature.');
}

// ============================================================
// MENU ITEM EXCEPTIONS
// ============================================================

class MenuItemNotFoundException extends DomainException {
  const MenuItemNotFoundException(String menuItemId)
      : super('That dish is no longer on the menu.');
}

class InsufficientInventoryException extends DomainException {
  const InsufficientInventoryException(
    String itemName,
    int requested,
    int available,
  ) : super('$itemName is out of stock right now.');
}

// ============================================================
// SEARCH EXCEPTIONS
// ============================================================

class PriceFilterOutOfRangeException extends DomainException {
  const PriceFilterOutOfRangeException()
      : super('Please enter a budget between \$1 and \$1000.');
}

class LocationUnavailableException extends DomainException {
  const LocationUnavailableException()
      : super('We couldn\'t get your location. Please enable location access and try again.');
}

// ============================================================
// CART EXCEPTIONS
// ============================================================

class MultiRestaurantCartException extends DomainException {
  const MultiRestaurantCartException()
      : super('Your cart already has items from another restaurant. Please clear it first.');
}

class ItemUnavailableException extends DomainException {
  const ItemUnavailableException(String itemName)
      : super('$itemName is currently unavailable.');
}

// ============================================================
// ORDER EXCEPTIONS
// ============================================================

class OrderNotFoundException extends DomainException {
  const OrderNotFoundException(String orderId)
      : super('We couldn\'t find that order.');
}

class InvalidOrderStateTransitionException extends DomainException {
  const InvalidOrderStateTransitionException(
    String currentState,
    String targetState,
  ) : super('This order can\'t be updated anymore.');
}

class EmptyCartException extends DomainException {
  const EmptyCartException()
      : super('Your cart is empty. Add items before placing an order.');
}

// ============================================================
// FIRESTORE / NETWORK EXCEPTIONS
// ============================================================

class PermissionDeniedException extends DomainException {
  const PermissionDeniedException()
      : super('You don\'t have permission to do that.');
}

class NetworkUnavailableException extends DomainException {
  const NetworkUnavailableException()
      : super('Check your internet connection and try again.');
}

class FirestoreTimeoutException extends DomainException {
  const FirestoreTimeoutException()
      : super('This is taking too long. Please try again.');
}

class FirestoreOperationException extends DomainException {
  const FirestoreOperationException(String message)
      : super('Something went wrong on our end. Please try again.');
}