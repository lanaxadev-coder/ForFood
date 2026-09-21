// ============================================================
// LOGIN EVENTS
// ============================================================
// Events dispatched to LoginBloc for the login form.
//
// The LoginBloc handles only the login form. On successful
// login, it dispatches AuthEventInitialize to the AuthBloc
// to trigger app-level navigation.
// ============================================================

/// Base class for all Login events.
abstract class LoginEvent {
  const LoginEvent();
}

/// Fired when user taps "Log In" on the login form.
class LoginEventSubmit extends LoginEvent {
  /// Email entered by the user.
  final String email;

  /// Password entered by the user.
  final String password;

  const LoginEventSubmit({
    required this.email,
    required this.password,
  });
}

/// Fired when user toggles password visibility.
class LoginEventTogglePasswordVisibility extends LoginEvent {
  const LoginEventTogglePasswordVisibility();
}

/// Fired when user taps "forgot password" link.
class LoginEventForgotPassword extends LoginEvent {
  final String email;

  const LoginEventForgotPassword({required this.email});
}