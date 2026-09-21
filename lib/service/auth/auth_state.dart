// ============================================================
// AUTH STATES
// ============================================================
// States emitted by AuthBloc in response to AuthEvents.
//
// The AuthBloc uses a sealed-class pattern where each state
// represents a distinct phase of the auth lifecycle:
//   - Initial: App starting, no auth check yet
//   - Loading: Auth operation in progress
//   - LoggedOut: No user signed in
//   - LoggedIn: User signed in (with role)
//   - Onboarding: First-time user, show onboarding
//   - Error: Auth operation failed
// ============================================================

import 'package:forfood/service/auth/auth_user.dart';

/// Base class for all Auth states.
abstract class AuthState {
  const AuthState();
}

/// Initial state — app starting, no auth check yet.
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// Loading state — auth operation in progress.
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// Logged out state — no user signed in.
class AuthStateLoggedOut extends AuthState {
  const AuthStateLoggedOut();
}

/// Onboarding state — first-time user, show onboarding screens.
class AuthStateOnboarding extends AuthState {
  const AuthStateOnboarding();
}

/// Logged in state — user signed in with role.
class AuthStateLoggedIn extends AuthState {
  final AuthUser user;

  const AuthStateLoggedIn({required this.user});
}

/// Error state — auth operation failed.
class AuthStateError extends AuthState {
  final String message;

  const AuthStateError({required this.message});
}