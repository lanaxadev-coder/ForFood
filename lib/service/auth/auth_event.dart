// ============================================================
// AUTH EVENTS
// ============================================================
// Events dispatched to AuthBloc for APP-LEVEL auth operations.
//
// Login and Signup form submissions are handled by
// LoginBloc and SignupBloc respectively — NOT here.
// ============================================================

import 'package:forfood/service/auth/auth_user.dart';

/// Base class for all Auth events.
abstract class AuthEvent {
  const AuthEvent();
}

/// Fired when the app starts to check current auth state.
class AuthEventInitialize extends AuthEvent {
  const AuthEventInitialize();
}

/// Fired when user taps "Log Out".
class AuthEventSignOut extends AuthEvent {
  const AuthEventSignOut();
}

/// Fired when user confirms account deletion.
class AuthEventDeleteAccount extends AuthEvent {
  const AuthEventDeleteAccount();
}

/// Fired when user requests password reset.
class AuthEventForgotPassword extends AuthEvent {
  final String email;

  const AuthEventForgotPassword({required this.email});
}

/// Fired when user changes password.
class AuthEventChangePassword extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthEventChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });
}


/// Fired when user taps "Sign in with Google".
class AuthEventGoogleSignIn extends AuthEvent {
  const AuthEventGoogleSignIn();
}

/// Fired when user successfully logs in or signs up.
class AuthEventLoggedIn extends AuthEvent {
  final AuthUser user;
  const AuthEventLoggedIn({required this.user});
}