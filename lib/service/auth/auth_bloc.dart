 // ============================================================
// AUTH BLOC — WITH DEBUG STATEMENTS
// ============================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/auth_provider.dart';
import 'package:forfood/service/auth/auth_user.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/notification/fcm_service.dart';
import 'package:forfood/utilities/friendly_error.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthProvider _authProvider;
  StreamSubscription<AuthUser?>? _authStateSubscription;

  AuthBloc(IAuthProvider authProvider)
      : _authProvider = authProvider,
        super(const AuthStateInitial()) {
    print('🔵 AUTH BLOC: Constructor called');
    on<AuthEventInitialize>(_onInitialize);
    on<AuthEventSignOut>(_onSignOut);
    on<AuthEventDeleteAccount>(_onDeleteAccount);
    on<AuthEventForgotPassword>(_onForgotPassword);
    on<AuthEventChangePassword>(_onChangePassword);
    on<AuthEventGoogleSignIn>(_onGoogleSignIn);
    on<AuthEventLoggedIn>(_onLoggedIn);
      add(const AuthEventInitialize());

  }
Future<void> _onInitialize(
  AuthEventInitialize event,
  Emitter<AuthState> emit,
) async {
  print('🔵 AUTH BLOC: _onInitialize started');
  emit(const AuthStateLoading());
  print('🔵 AUTH BLOC: Emitted AuthStateLoading');


  if (isClosed) {
    print('❌ AUTH BLOC: Block is closed, returning');
    return;
  }

final user = await _authProvider.getCurrentUser();  // ✅ AWAIT!
  print('🔵 AUTH BLOC: currentUser = $user');

  if (user != null) {
    print('✅ AUTH BLOC: User found — emitting AuthStateLoggedIn');
    // ✅ User from provider already has correct role from Firestore
    emit(AuthStateLoggedIn(user: user));
    print('🔵 AUTH BLOC: isClosed after emit = $isClosed');
    print('🔵 AUTH BLOC: state after emit = $state');
  } else {
    print('✅ AUTH BLOC: No user — emitting AuthStateLoggedOut');
    emit(const AuthStateLoggedOut());
  }
}  Future<void> _onSignOut(
    AuthEventSignOut event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AUTH BLOC: _onSignOut started');
    emit(const AuthStateLoading());

    try {
      await _authProvider.signOut();
      print('✅ AUTH BLOC: SignOut success — emitting LoggedOut');
      emit(const AuthStateLoggedOut());
    } on AuthenticationException catch (e) {
      print('❌ AUTH BLOC: SignOut failed: ${e.message}');
      emit(AuthStateError(message: friendlyError(e)));
    } catch (e) {
      print('❌ AUTH BLOC: SignOut unknown error: $e');
      emit(AuthStateError(message: 'Sign out failed: $e'));
    }
  }Future<void> _onDeleteAccount(
  AuthEventDeleteAccount event,
  Emitter<AuthState> emit,
) async {
  print('🐛 BLOC: _onDeleteAccount started');
  emit(const AuthStateLoading());

  try {
    await _authProvider.deleteAccount();
    print('🐛 BLOC: provider.deleteAccount() succeeded');
    emit(const AuthStateLoggedOut());
    print('🐛 BLOC: emitted AuthStateLoggedOut');
  } on AccountDeletionException catch (e) {
    print('🐛 BLOC: AccountDeletionException — ${e.message}');
    emit(AuthStateError(message: friendlyError(e)));
  } on AuthenticationException catch (e) {
    print('🐛 BLOC: AuthenticationException — ${e.message}');
    emit(AuthStateError(message: friendlyError(e)));
  } catch (e) {
    print('🐛 BLOC: unknown — $e');
    emit(AuthStateError(message: 'Account deletion failed: $e'));
  }
}  Future<void> _onForgotPassword(
    AuthEventForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AUTH BLOC: _onForgotPassword started for ${event.email}');
    emit(const AuthStateLoading());

    try {
      await _authProvider.sendPasswordResetEmail(event.email);
      print('✅ AUTH BLOC: Reset email sent');
      emit(const AuthStateLoggedOut());
    } on AuthenticationException catch (e) {
      print('❌ AUTH BLOC: Reset failed: ${e.message}');
      emit(AuthStateError(message: friendlyError(e)));
    } catch (e) {
      print('❌ AUTH BLOC: Reset unknown error: $e');
      emit(AuthStateError(message: 'Password reset failed: $e'));
    }
  }

  Future<void> _onChangePassword(
    AuthEventChangePassword event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AUTH BLOC: _onChangePassword started');
    emit(const AuthStateLoading());

    try {
      await _authProvider.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      print('✅ AUTH BLOC: Password changed');
      emit(const AuthStateLoggedOut());
    } on InvalidCredentialsException catch (e) {
      print('❌ AUTH BLOC: Invalid credentials: ${e.message}');
      emit(AuthStateError(message: friendlyError(e)));
    } on AuthenticationException catch (e) {
      print('❌ AUTH BLOC: Auth error: ${e.message}');
      emit(AuthStateError(message: friendlyError(e)));
    } catch (e) {
      print('❌ AUTH BLOC: Change password error: $e');
      emit(AuthStateError(message: 'Password change failed: $e'));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthEventGoogleSignIn event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AUTH BLOC: _onGoogleSignIn started');
    emit(const AuthStateLoading());

    try {
      final user = await _authProvider.signInWithGoogle();
      print('✅ AUTH BLOC: Google sign in success: ${user.id}');
      emit(AuthStateLoggedIn(user: user));
    } on AuthenticationException catch (e) {
      print('❌ AUTH BLOC: Google sign in failed: ${e.message}');
      emit(AuthStateError(message: friendlyError(e)));
    } catch (e) {
      print('❌ AUTH BLOC: Google sign in unknown error: $e');
      emit(AuthStateError(message: 'Google sign-in failed: $e'));
    }
  }

  Future<void> _onLoggedIn(
    AuthEventLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 AUTH BLOC: _onLoggedIn called with user: ${event.user.id}');
    print('🔵 AUTH BLOC: Emitting AuthStateLoggedIn');
    emit(AuthStateLoggedIn(user: event.user));
    print('✅ AUTH BLOC: AuthStateLoggedIn emitted');
print('🔵 AUTH BLOC: isClosed after emit = $isClosed');
 try {
    await FcmService.instance.saveTokenToFirestore();
  } catch (_) {}
print('🔵 AUTH BLOC: current state after emit = $state');
  }

  @override
  Future<void> close() {
    print('🔵 AUTH BLOC: close() called');
    _authStateSubscription?.cancel();
    return super.close();
  }
}