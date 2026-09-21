// ============================================================
// SIGNUP STATES
// ============================================================

abstract class SignupState {
  const SignupState();
}

class SignupStateInitial extends SignupState {
  const SignupStateInitial();
}

class SignupStateLoading extends SignupState {
  const SignupStateLoading();
}

/// Email verified — user tapped the verification link.
class SignupStateEmailVerified extends SignupState {
  const SignupStateEmailVerified();
}

/// Waiting for verification — email sent, awaiting user to open link.
class SignupStateWaitingForVerification extends SignupState {
  const SignupStateWaitingForVerification();
}

class SignupStateSuccess extends SignupState {
  const SignupStateSuccess();
}

class SignupStateError extends SignupState {
  final String? fullNameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? addressError;
  final String? generalError;

  const SignupStateError({
    this.fullNameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.addressError,
    this.generalError,
  });
}

class SignupStatePasswordVisibility extends SignupState {
  final bool isPasswordVisible;
  const SignupStatePasswordVisibility({required this.isPasswordVisible});
}

class SignupStateConfirmPasswordVisibility extends SignupState {
  final bool isConfirmPasswordVisible;
  const SignupStateConfirmPasswordVisibility({
    required this.isConfirmPasswordVisible,
  });
}
/// Email verified for an existing verified account (during signup attempt).
/// Caller should navigate to Login screen.
class SignupStateEmailAlreadyRegistered extends SignupState {
  const SignupStateEmailAlreadyRegistered();
}

/// User tapped "I've Verified" but the email isn't verified yet.
/// User tapped "I've Verified" but the email isn't verified yet.
/// Includes a timestamp so each emit is unique (prevents bloc deduplication).
class SignupStateNotVerifiedYet extends SignupState {
  final int timestamp;

  const SignupStateNotVerifiedYet({required this.timestamp});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignupStateNotVerifiedYet &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp;

  @override
  int get hashCode => timestamp.hashCode;
}