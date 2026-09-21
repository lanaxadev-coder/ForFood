// ============================================================
// LOGIN STATES
// ============================================================

/// Base class for all Login states.
abstract class LoginState {
  const LoginState();
}

/// Initial state — form is empty and ready for input.
class LoginStateInitial extends LoginState {
  const LoginStateInitial();
}

/// Loading state — login request in progress.
class LoginStateLoading extends LoginState {
  const LoginStateLoading();
}

/// Success state — login successful.
class LoginStateSuccess extends LoginState {
  const LoginStateSuccess();
}

/// Error state — login failed with field-specific or general error.
class LoginStateError extends LoginState {
  /// Error shown under the email field.
  final String? emailError;

  /// Error shown under the password field.
  final String? passwordError;

  /// General error shown via SnackBar.
  final String? generalError;

  /// ✅ ADDED: Indicates the email is not verified and user should be redirected to verify screen.
  final bool isEmailNotVerified;

  const LoginStateError({
    this.emailError,
    this.passwordError,
    this.generalError,
    this.isEmailNotVerified = false,
  });
}

/// Password visibility state.
class LoginStatePasswordVisibility extends LoginState {
  final bool isPasswordVisible;

  const LoginStatePasswordVisibility({required this.isPasswordVisible});
}