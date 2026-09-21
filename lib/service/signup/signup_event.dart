import 'package:forfood/service/auth/user_role.dart';

abstract class SignupEvent {
  const SignupEvent();
}

class SignupEventSubmit extends SignupEvent {
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final UserRole role;
  final String? address;
  final double? latitude;    // ← ADD
  final double? longitude;  

  const SignupEventSubmit({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.role,
    this.address,
      this.latitude,    // ← ADD
    this.longitude,  
  });
}

class SignupEventVerifyEmail extends SignupEvent {
  final String email;
  final String password;
  final String fullName; // ✅ Add

  const SignupEventVerifyEmail({
    required this.email,
    required this.password,
        this.fullName = '',

  });
}

/// Fired when user taps "Verify" button to check verification status.
class SignupEventCheckVerification extends SignupEvent {
  const SignupEventCheckVerification();
}

class SignupEventTogglePasswordVisibility extends SignupEvent {
  const SignupEventTogglePasswordVisibility();
}

class SignupEventToggleConfirmPasswordVisibility extends SignupEvent {
  const SignupEventToggleConfirmPasswordVisibility();
}
/// Fired when user taps "Resend" on the Verify Email screen.
class SignupEventResendEmail extends SignupEvent {
  final String email;
  final String password;

  const SignupEventResendEmail({
    required this.email,
    required this.password,
  });
}