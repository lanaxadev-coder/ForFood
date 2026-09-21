// ============================================================
// NOTIFICATION STATES
// ============================================================

import 'package:forfood/models/notification_model.dart';

/// Base class for all Notification states.
abstract class NotificationState {
  const NotificationState();
}

/// Initial state.
class NotificationStateInitial extends NotificationState {
  const NotificationStateInitial();
}

/// Loading state.
class NotificationStateLoading extends NotificationState {
  const NotificationStateLoading();
}

/// Loaded state with notifications.
class NotificationStateLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationStateLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

/// Error state.
class NotificationStateError extends NotificationState {
  final String message;

  const NotificationStateError({required this.message});
}