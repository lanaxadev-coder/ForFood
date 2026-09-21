import 'package:forfood/service/auth/auth_user.dart';
import 'package:forfood/service/auth/user_role.dart';

abstract class IAuthProvider {
  Stream<AuthUser?> authStateChanges();
Future<AuthUser?> getCurrentUser();  // ✅ Change to Future
  /// Creates a temp user and sends verification email.
  /// Returns the created user.
  Future<AuthUser> createTempUserWithVerification({
    required String email,
    required String password,
      String fullName = 'User', // ✅ ADDED

  });

  /// Checks if the current user's email is verified.
  /// Reloads from Firebase to get fresh state.
  Future<bool> isEmailVerified();

  /// Completes signup: updates display name and Firestore.
  /// Throws if email is not verified.
  Future<AuthUser> completeSignup({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
      double? latitude,      // ← ADD
  double? longitude,     // ← ADD
  String? address,   
  });

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signInForEmailVerification({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<AuthUser> signInWithGoogle();
  Future<void> resendVerificationEmail({
  required String email,
  required String password,
});
}