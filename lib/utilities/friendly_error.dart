import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';

/// Turns ANY error into a sentence a normal person understands.
/// Use this everywhere you show an error to the user.
String friendlyError(Object error) {
  // ── Our own domain exceptions ──
  if (error is DomainException) {
    return error.message;
  }

  // ── Firebase Auth ──
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Wrong email or password. Please try again.';
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in instead.';
      case 'weak-password':
        return 'Your password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'requires-recent-login':
        return 'Please log in again before doing this.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Firestore ──
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to do that.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Connection issue. Please check your internet and try again.';
      case 'not-found':
        return 'We couldn\'t find that. Please refresh and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Fallback ──
  return 'Something went wrong. Please try again.';
}