// ============================================================
// FIREBASE AUTH PROVIDER — WITH DEBUG STATEMENTS
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:forfood/models/restaurant_model.dart';

import 'package:forfood/models/user_model.dart';
import 'package:forfood/service/auth/auth_provider.dart';
import 'package:forfood/service/auth/auth_user.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/utilities/geohach_util.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthProvider implements IAuthProvider {
  final FirebaseAuth _auth;
  final FirestoreProvider _firestoreProvider;

  FirebaseAuthProvider({
    FirebaseAuth? auth,
    FirestoreProvider? firestoreProvider,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestoreProvider = firestoreProvider ?? FirestoreProvider() {
    print('🔵 FIREBASE AUTH PROVIDER: Constructor called');
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    print('🔵 FIREBASE AUTH PROVIDER: authStateChanges() called');
     return _auth.authStateChanges().asyncMap((firebaseUser) async {
  print('🔵 FIREBASE AUTH PROVIDER: authStateChanges fired: $firebaseUser');
  if (firebaseUser == null) return null;

  // ✅ Same check here
  if (!firebaseUser.emailVerified) {
    print('⚠️ FIREBASE AUTH PROVIDER: authStateChanges → not verified');
    return null;
  }

  try {
    final userModel =
        await _firestoreProvider.getUserById(firebaseUser.uid);
    print('✅ FIREBASE AUTH PROVIDER: User from Firestore: ${userModel.fullName}');
    return _toAuthUser(userModel);
  } on UserNotFoundException {
    return null;
  } catch (e) {
    print('⚠️ FIREBASE AUTH PROVIDER: Firestore fetch failed: $e');
    return AuthUser(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber,
      profileImageUrl: firebaseUser.photoURL,
      role: UserRole.user,
    );
  }
});
  
  }
@override
Future<AuthUser?> getCurrentUser() async {
  final user = _auth.currentUser;
  print('🔵 FIREBASE AUTH PROVIDER: getCurrentUser = ${user?.email ?? "null"}');
  if (user == null) return null;

  // ✅ CRITICAL: Reject unverified users — they must finish signup
  // Otherwise users who close the app before verifying get a "logged in" state.
  if (!user.emailVerified) {
    print('⚠️ FIREBASE AUTH PROVIDER: User email not verified → signing out');
    await _auth.signOut();
    return null;
  }

  try {
    final userModel = await _firestoreProvider.getUserById(user.uid);
    print('✅ FIREBASE AUTH PROVIDER: Role from Firestore: ${userModel.role}');
    return _toAuthUser(userModel);
  } on UserNotFoundException {
    // User was deleted from Firestore — force sign out
    print('⚠️ FIREBASE AUTH PROVIDER: User missing in Firestore → signing out');
    await _auth.signOut();
    return null;
  } catch (e) {
    print('⚠️ FIREBASE AUTH PROVIDER: Firestore fetch failed: $e');
    return AuthUser(
      id: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.photoURL,
      role: UserRole.user,
    );
  }
}
  @override
  Future<AuthUser> createTempUserWithVerification({
    required String email,
    required String password,
      String fullName = 'User', // ✅ Add default

  }) async {
    print('🔵 FIREBASE AUTH PROVIDER: createTempUserWithVerification for $email');
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ FIREBASE AUTH PROVIDER: User created');

      final user = userCredential.user!;
  await user.updateDisplayName(fullName); // Instead of 'userForfood5555'
      await user.sendEmailVerification();
      print('✅ FIREBASE AUTH PROVIDER: Verification email sent');

      final userModel = UserModel(
        id: user.uid,
  fullName: fullName,   // ✅ Use the real name passed in
        email: email,
        phoneNumber: null,
        profileImageUrl: null,
          role: UserRole.user,  // ✅ ADD THIS

        createdAt: DateTime.now(),
      );
      await _firestoreProvider.createUser(userModel);
      print('✅ FIREBASE AUTH PROVIDER: Firestore document created');

      return _toAuthUser(userModel);
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH PROVIDER: FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          throw const EmailAlreadyInUseException();
        case 'invalid-email':
          throw const AuthenticationException(
              'Invalid email address. Please check and try again.');
        case 'weak-password':
          throw const AuthenticationException(
              'Password is too weak. Use at least 6 characters.');
        default:
          throw AuthenticationException(
              'Sign up failed: ${e.message ?? 'Unknown error'}');
      }
    }
  }

 @override
Future<AuthUser> completeSignup({
  required String email,
  required String password,
  required String fullName,
  required UserRole role,
  double? latitude,
  double? longitude,
  String? address,
}) async {
  print('🔵 FIREBASE AUTH PROVIDER: completeSignup for $email');
  try {
    var user = _auth.currentUser;
    if (user == null) {
      print('⚠️ FIREBASE AUTH PROVIDER: No current user — signing in');
      await signInForEmailVerification(email: email, password: password);
      user = _auth.currentUser;
    }

    if (user == null) {
      throw const AuthenticationException('Please verify your email first');
    }

    await user.reload();
    final refreshedUser = _auth.currentUser!;
    print('🔵 FIREBASE AUTH PROVIDER: emailVerified = ${refreshedUser.emailVerified}');

    if (!refreshedUser.emailVerified) {
      throw const EmailNotVerifiedException();
    }
    // ✅ CRITICAL: Force refresh the ID token so security rules
// see email_verified = true. Without this, restaurant/order
// creation fails because the token still has the old claim.
await refreshedUser.getIdToken(true);
print('✅ FIREBASE AUTH PROVIDER: Token refreshed after verification');

    await refreshedUser.updateDisplayName(fullName);
    print('✅ FIREBASE AUTH PROVIDER: displayName updated to $fullName');

    // ✅ Update UserModel in Firestore
    final userModel = UserModel(
      id: refreshedUser.uid,
      fullName: fullName,
      email: refreshedUser.email ?? email,
      phoneNumber: refreshedUser.phoneNumber,
      profileImageUrl: refreshedUser.photoURL,
        role: role,  // ✅ ADD THIS

      createdAt: DateTime.now(),
    );
    await _firestoreProvider.updateUser(userModel);
    print('✅ FIREBASE AUTH PROVIDER: Firestore user updated');

    // ✅ If restaurant, create RestaurantModel in Firestore
    if (role == UserRole.restaurant) {
      final restaurantLat = latitude ?? 36.7538;
final restaurantLng = longitude ?? 3.0588;
      final restaurant = RestaurantModel(
        id: '',
        ownerId: refreshedUser.uid,
        name: fullName,
        description: '',
        address: address ?? '',
        latitude: latitude ?? 36.7538,
        longitude: longitude ?? 3.0588,
geohash: GeohashUtil.encode(
    latitude: restaurantLat,
    longitude: restaurantLng,
  ),           rating: 0.0,
        ratingCount: 0,
        isDeliveryEnabled: true,
        subscriptionActive: false,
        isFeatured: false,
        views: 0,
        createdAt: DateTime.now(),
      );
      await _firestoreProvider.createRestaurant(restaurant);
      print('✅ FIREBASE AUTH PROVIDER: Restaurant created in Firestore');
    }

    return _toAuthUser(userModel);
  } on EmailNotVerifiedException {
    print('❌ FIREBASE AUTH PROVIDER: Email not verified');
    rethrow;
  } on AuthenticationException {
    rethrow;
  } on FirebaseAuthException catch (e) {
    print('❌ FIREBASE AUTH PROVIDER: FirebaseAuthException: ${e.code}');
    throw AuthenticationException(
        'Sign up failed: ${e.message ?? 'Unknown error'}');
  }
}

  @override
  Future<bool> isEmailVerified() async {
    print('🔵 FIREBASE AUTH PROVIDER: isEmailVerified() called');
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ FIREBASE AUTH PROVIDER: No current user');
      return false;
    }
    await user.reload();
    final result = _auth.currentUser?.emailVerified ?? false;
    print('🔵 FIREBASE AUTH PROVIDER: isEmailVerified = $result');
    return result;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    print('🔵 FIREBASE AUTH PROVIDER: signInWithEmail for $email');
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      print('✅ FIREBASE AUTH PROVIDER: Signed in, emailVerified=${user.emailVerified}, name=${user.displayName}');

      if (!user.emailVerified) {
        print('❌ FIREBASE AUTH PROVIDER: Email not verified');
        throw const EmailNotVerifiedException();
      }

    

      final userModel = await _firestoreProvider.getUserById(user.uid);
      print('✅ FIREBASE AUTH PROVIDER: Firestore user: ${userModel.fullName}');
      return _toAuthUser(userModel);
    } on EmailNotVerifiedException {
      rethrow;
    } on SignupIncompleteException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH PROVIDER: FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          throw const InvalidCredentialsException();
        case 'invalid-email':
          throw const AuthenticationException(
              'Invalid email address. Please check and try again.');
        default:
          throw AuthenticationException(
              'Login failed: ${e.message ?? 'Unknown error'}');
      }
    }
  }

  @override
  Future<AuthUser> signInForEmailVerification({
    required String email,
    required String password,
  }) async {
    print('🔵 FIREBASE AUTH PROVIDER: signInForEmailVerification for $email');
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;
      final userModel = await _firestoreProvider.getUserById(user.uid);
      return _toAuthUser(userModel);
    } on UserNotFoundException {
      print('⚠️ FIREBASE AUTH PROVIDER: User not in Firestore — using Auth data');
      final user = _auth.currentUser!;
      return AuthUser(
        id: user.uid,
        fullName: user.displayName ?? '',
        email: user.email ?? '',
        phoneNumber: user.phoneNumber,
        profileImageUrl: user.photoURL,
        role: _getRoleFromEmail(user.email),
      );
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH PROVIDER: FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          throw const InvalidCredentialsException();
        default:
          throw AuthenticationException(
              'Login failed: ${e.message ?? 'Unknown error'}');
      }
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    print('🔵 FIREBASE AUTH PROVIDER: sendPasswordResetEmail for $email');
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ FIREBASE AUTH PROVIDER: Reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH PROVIDER: Reset failed: ${e.code}');
      throw AuthenticationException(
          'Failed to send reset email: ${e.message}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    print('🔵 FIREBASE AUTH PROVIDER: changePassword called');
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationException('No user is currently signed in.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      print('✅ FIREBASE AUTH PROVIDER: Password changed');
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH PROVIDER: Change failed: ${e.code}');
      throw AuthenticationException(
          'Failed to change password: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    print('🔵 FIREBASE AUTH PROVIDER: signOut called');
    await _auth.signOut();
    print('✅ FIREBASE AUTH PROVIDER: Signed out');
  }

  @override
  Future<void> deleteAccount() async {
    print('🔵 FIREBASE AUTH PROVIDER: deleteAccount called');
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestoreProvider.deleteUser(user.uid);
    await user.delete();
    print('✅ FIREBASE AUTH PROVIDER: Account deleted');
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    print('🔵 FIREBASE AUTH PROVIDER: signInWithGoogle called');
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthenticationException('Google sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      print('✅ FIREBASE AUTH PROVIDER: Google signed in: ${user.email}');

      try {
        final userModel = await _firestoreProvider.getUserById(user.uid);
        return _toAuthUser(userModel);
      } on UserNotFoundException {
        final userModel = UserModel(
          id: user.uid,
          fullName: user.displayName ?? 'User',
          email: user.email ?? '',
          phoneNumber: user.phoneNumber,
          profileImageUrl: user.photoURL,
                  role: UserRole.user,  // ✅ ADD ROLE

          createdAt: DateTime.now(), 
          
        );
        await _firestoreProvider.createUser(userModel);
        return _toAuthUser(userModel);
      }
    } catch (e) {
      print('❌ FIREBASE AUTH PROVIDER: Google sign in failed: $e');
      throw AuthenticationException('Google sign-in failed: $e');
    }
  }

  AuthUser _toAuthUser(UserModel userModel) {
    return AuthUser(
      id: userModel.id,
      fullName: userModel.fullName,
      email: userModel.email,
      phoneNumber: userModel.phoneNumber,
      profileImageUrl: userModel.profileImageUrl,
    role: userModel.role,  // ✅ Get from UserModel, not email!
    );
  }

  UserRole _getRoleFromEmail(String? email) {
    return (email != null && email.contains('@restaurant.forfood.com'))
        ? UserRole.restaurant
        : UserRole.user;
  }


  @override
Future<void> resendVerificationEmail({
  required String email,
  required String password,
}) async {
  try {
    // Sign in with existing credentials
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const AuthenticationException('Could not sign in to resend email');
    }

    // Only resend if not already verified
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      print('✅ Resend: verification email sent to $email');
    }

    // Sign out to leave clean state (VerifyEmailView doesn't need session)
    await _auth.signOut();
  } on FirebaseAuthException catch (e) {
    throw AuthenticationException('Failed to resend: ${e.message}');
  }
}
}