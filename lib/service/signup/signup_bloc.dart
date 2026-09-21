// ============================================================
// SIGNUP BLOC — WITH DEBUG STATEMENTS
// ============================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_provider.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/signup/signup_event.dart';
import 'package:forfood/service/signup/signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final IAuthProvider _authProvider;
  final AuthBloc _authBloc;

  SignupBloc({
    required IAuthProvider authProvider,
    required AuthBloc authBloc,
  })  : _authProvider = authProvider,
        _authBloc = authBloc,
        super(const SignupStateInitial()) {
    print('🔵 SIGNUP BLOC: Constructor called');
    on<SignupEventSubmit>(_onSubmit);
    on<SignupEventVerifyEmail>(_onVerifyEmail);
    on<SignupEventCheckVerification>(_onCheckVerification);
    on<SignupEventTogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<SignupEventToggleConfirmPasswordVisibility>(
        _onToggleConfirmPasswordVisibility);
        on<SignupEventResendEmail>(_onResendEmail);
  }

  Future<void> _onSubmit(
    SignupEventSubmit event,
    Emitter<SignupState> emit,
  ) async {
    print('🔵 SIGNUP BLOC: _onSubmit started');
    print('🔵 SIGNUP BLOC: Current state: $state');

    if (state is SignupStateLoading) {
      print('⚠️ SIGNUP BLOC: Already loading, ignoring');
      return;
    }

    final validationError = _validateFields(event);
    if (validationError != null) {
      print('❌ SIGNUP BLOC: Validation failed');
      emit(validationError);
      return;
    }

    print('🔵 SIGNUP BLOC: Emitting SignupStateLoading');
    emit(const SignupStateLoading());

    try {
      print('🔵 SIGNUP BLOC: Calling completeSignup');
      final user = await _authProvider.completeSignup(
        email: event.email.trim(),
        password: event.password,
        fullName: event.fullName.trim(),
        role: event.role,
          latitude: event.latitude,    // ← ADD
        longitude: event.longitude,  // ← ADD
        address: event.address, 
      );
      print('✅ SIGNUP BLOC: User signed up: ${user.id}');
      print('🔵 SIGNUP BLOC: Dispatching AuthEventLoggedIn');
      _authBloc.add(AuthEventLoggedIn(user: user));
      print('✅ SIGNUP BLOC: AuthEventLoggedIn dispatched');
      print('🔵 SIGNUP BLOC: Emitting SignupStateSuccess');
      emit(const SignupStateSuccess());
      print('✅ SIGNUP BLOC: SignupStateSuccess emitted');
    } on EmailNotVerifiedException catch (e) {
      print('❌ SIGNUP BLOC: EmailNotVerifiedException: ${e.message}');
      emit(SignupStateError(generalError: e.message));
    } on InvalidCredentialsException {
      print('❌ SIGNUP BLOC: InvalidCredentialsException');
      emit(const SignupStateError(
          generalError: 'Invalid email or password. Please try again.'));
    } on AuthenticationException catch (e) {
      print('❌ SIGNUP BLOC: AuthenticationException: ${e.message}');
      emit(SignupStateError(generalError: e.message));
    } catch (e) {
      print('❌ SIGNUP BLOC: Unknown error: $e');
      emit(SignupStateError(generalError: 'Sign up failed: $e'));
    }
  }

  Future<void> _onVerifyEmail(
    SignupEventVerifyEmail event,
    Emitter<SignupState> emit,
  ) async {
    print('🔵 SIGNUP BLOC: _onVerifyEmail started');
    if (state is SignupStateLoading) return;

    final email = event.email.trim();
    final password = event.password;

    if (email.isEmpty) {
      print('❌ SIGNUP BLOC: Email is empty');
      emit(const SignupStateError(emailError: 'Email is required'));
      return;
    }
    if (!_isValidEmail(email)) {
      print('❌ SIGNUP BLOC: Invalid email format');
      emit(const SignupStateError(
          emailError: 'Please enter a valid email address'));
      return;
    }
    if (password.isEmpty) {
      print('❌ SIGNUP BLOC: Password is empty');
      emit(const SignupStateError(passwordError: 'Password is required'));
      return;
    }
    if (password.length < 6) {
      print('❌ SIGNUP BLOC: Password too short');
      emit(const SignupStateError(
          passwordError: 'Password must be at least 6 characters'));
      return;
    }

    print('🔵 SIGNUP BLOC: Emitting SignupStateLoading');
    emit(const SignupStateLoading());

    try {
      print('🔵 SIGNUP BLOC: Calling createTempUserWithVerification');
      await _authProvider.createTempUserWithVerification(
        email: email,
        password: password,
          fullName: event.fullName, // ✅ Pass

      );
      print('✅ SIGNUP BLOC: Temp user created, emitting WaitingForVerification');
      emit(const SignupStateWaitingForVerification());
    } on EmailAlreadyInUseException {
      print('⚠️ SIGNUP BLOC: Email already exists — handling existing user');
      await _handleExistingUser(email, password, emit);
    } on AuthenticationException catch (e) {
      print('❌ SIGNUP BLOC: AuthenticationException: ${e.message}');
      emit(SignupStateError(generalError: e.message));
    } catch (e) {
      print('❌ SIGNUP BLOC: Unknown error: $e');
      emit(SignupStateError(generalError: 'Email verification failed: $e'));
    }
  }
Future<void> _onCheckVerification(
  SignupEventCheckVerification event,
  Emitter<SignupState> emit,
) async {
  print('🔵 SIGNUP BLOC: _onCheckVerification started');
  try {
    final isVerified = await _authProvider.isEmailVerified();
    print('🔵 SIGNUP BLOC: isEmailVerified = $isVerified');
    if (isVerified) {
      print('✅ SIGNUP BLOC: Email verified');
      emit(const SignupStateEmailVerified());
    } else {
      print('⚠️ SIGNUP BLOC: Not verified yet');
      // ✅ Emit distinct state so listener always fires
emit(SignupStateNotVerifiedYet(
  timestamp: DateTime.now().millisecondsSinceEpoch,
));    }
  } catch (e) {
    print('❌ SIGNUP BLOC: Check failed: $e');
    emit(SignupStateError(generalError: 'Verification check failed: $e'));
  }
}
  void _onTogglePasswordVisibility(
    SignupEventTogglePasswordVisibility event,
    Emitter<SignupState> emit,
  ) {
    final currentState = state;
    if (currentState is SignupStatePasswordVisibility) {
      emit(SignupStatePasswordVisibility(
        isPasswordVisible: !currentState.isPasswordVisible,
      ));
    } else {
      emit(const SignupStatePasswordVisibility(isPasswordVisible: true));
    }
  }

  void _onToggleConfirmPasswordVisibility(
    SignupEventToggleConfirmPasswordVisibility event,
    Emitter<SignupState> emit,
  ) {
    final currentState = state;
    if (currentState is SignupStateConfirmPasswordVisibility) {
      emit(SignupStateConfirmPasswordVisibility(
        isConfirmPasswordVisible: !currentState.isConfirmPasswordVisible,
      ));
    } else {
      emit(const SignupStateConfirmPasswordVisibility(
          isConfirmPasswordVisible: true));
    }
  }

  Future<void> _handleExistingUser(
    String email,
    String password,
    Emitter<SignupState> emit,
  ) async {
    print('🔵 SIGNUP BLOC: _handleExistingUser started');
    try {
      await _authProvider.signInForEmailVerification(
        email: email,
        password: password,
      );
      final isVerified = await _authProvider.isEmailVerified();
      await _authProvider.signOut();
      print('🔵 SIGNUP BLOC: Existing user isVerified = $isVerified');
      if (isVerified) {
        emit(const SignupStateEmailVerified());
      } else {
        emit(const SignupStateWaitingForVerification());
      }
    } on InvalidCredentialsException {
      print('❌ SIGNUP BLOC: Wrong password for existing email');
      emit(const SignupStateError(
          emailError:
              'An account already exists with this email. Please log in.'));
    } catch (e) {
      await _authProvider.signOut();
      print('❌ SIGNUP BLOC: Handle existing user error: $e');
      emit(SignupStateError(generalError: 'Failed to resend verification: $e'));
    }
  }

  SignupStateError? _validateFields(SignupEventSubmit event) {
    if (event.fullName.trim().isEmpty) {
      return const SignupStateError(fullNameError: 'Full name is required');
    }
    if (event.email.trim().isEmpty) {
      return const SignupStateError(emailError: 'Email is required');
    }
    if (!_isValidEmail(event.email.trim())) {
      return const SignupStateError(
          emailError: 'Please enter a valid email address');
    }
    if (event.password.isEmpty) {
      return const SignupStateError(passwordError: 'Password is required');
    }
    if (event.password.length < 6) {
      return const SignupStateError(
          passwordError: 'Password must be at least 6 characters');
    }
    if (event.confirmPassword != event.password) {
      return const SignupStateError(
          confirmPasswordError: 'Passwords do not match');
    }
    if (event.role == UserRole.restaurant &&
        (event.address == null || event.address!.trim().isEmpty)) {
      return const SignupStateError(
          addressError: 'Restaurant address is required');
    }
    return null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _onResendEmail(
  SignupEventResendEmail event,
  Emitter<SignupState> emit,
) async {
  print('🔵 SIGNUP BLOC: _onResendEmail started');
  emit(const SignupStateLoading());

  try {
    await _authProvider.resendVerificationEmail(
      email: event.email.trim(),
      password: event.password,
    );
    print('✅ SIGNUP BLOC: Verification email resent');
    emit(const SignupStateWaitingForVerification());
  } on AuthenticationException catch (e) {
    print('❌ SIGNUP BLOC: Resend failed: ${e.message}');
    emit(SignupStateError(generalError: e.message));
  } catch (e) {
    print('❌ SIGNUP BLOC: Resend error: $e');
    emit(SignupStateError(generalError: 'Failed to resend email: $e'));
  }
}
}