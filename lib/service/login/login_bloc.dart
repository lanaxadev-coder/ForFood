// ============================================================
// LOGIN BLOC — WITH DEBUG STATEMENTS (FOCUS ON FLOW)
// ============================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/login/login_event.dart';
import 'package:forfood/service/login/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final IAuthProvider _authProvider;
  final AuthBloc _authBloc;

  LoginBloc({
    required IAuthProvider authProvider,
    required AuthBloc authBloc,
  })  : _authProvider = authProvider,
        _authBloc = authBloc,
        super(const LoginStateInitial()) {
    on<LoginEventSubmit>(_onSubmit);
    on<LoginEventTogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<LoginEventForgotPassword>(_onForgotPassword);
  }

  Future<void> _onSubmit(
    LoginEventSubmit event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginStateLoading) {
      return;
    }

    final email = event.email.trim();
    final password = event.password;

    if (email.isEmpty) {
      emit(const LoginStateError(emailError: 'Email is required'));
      return;
    }

    if (password.isEmpty) {
      emit(const LoginStateError(passwordError: 'Password is required'));
      return;
    }

    emit(const LoginStateLoading());

    try {
      final user = await _authProvider.signInWithEmail(
        email: email,
        password: password,
      );
      _authBloc.add(AuthEventLoggedIn(user: user));
      emit(const LoginStateSuccess());
    } on EmailAlreadyInUseException catch (e) {
      emit(LoginStateError(emailError: e.message));
    } on InvalidCredentialsException catch (e) {
      emit(LoginStateError(generalError: e.message));
    } on EmailNotVerifiedException catch (e) {
      // ✅ Special flag to redirect to VerifyEmailView
      emit(LoginStateError(
        generalError: e.message,
        isEmailNotVerified: true,
      ));
    } on SignupIncompleteException catch (e) {
      emit(LoginStateError(generalError: e.message));
    } on AuthenticationException catch (e) {
      emit(LoginStateError(generalError: e.message));
    } on NetworkUnavailableException catch (e) {
      emit(LoginStateError(generalError: e.message));
    } catch (e) {
      emit(LoginStateError(generalError: 'Login failed: $e'));
    }
  }

  void _onTogglePasswordVisibility(
    LoginEventTogglePasswordVisibility event,
    Emitter<LoginState> emit,
  ) {
    final currentState = state;
    if (currentState is LoginStatePasswordVisibility) {
      emit(LoginStatePasswordVisibility(
        isPasswordVisible: !currentState.isPasswordVisible,
      ));
    } else {
      emit(const LoginStatePasswordVisibility(isPasswordVisible: true));
    }
  }

  Future<void> _onForgotPassword(
    LoginEventForgotPassword event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginStateLoading) return;

    final email = event.email.trim();
    if (email.isEmpty) {
      emit(const LoginStateError(emailError: 'Email is required'));
      return;
    }

    emit(const LoginStateLoading());

    try {
      await _authProvider.sendPasswordResetEmail(email);
      emit(const LoginStateSuccess());
    } on AuthenticationException catch (e) {
      emit(LoginStateError(generalError: e.message));
    } catch (e) {
      emit(LoginStateError(generalError: 'Password reset failed: $e'));
    }
  }
}