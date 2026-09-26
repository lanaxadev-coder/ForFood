// ============================================================
// NOTIFICATION EVENTS
// ============================================================

import 'package:forfood/models/notification_model.dart';

/// Base class for all Notification events.
abstract class NotificationEvent {
  const NotificationEvent();
}

/// Fired when a new notification is created.
class NotificationEventCreate extends NotificationEvent {
  final NotificationModel notification;

  const NotificationEventCreate({required this.notification});
}

/// Fired to fetch notifications for a recipient.
class NotificationEventFetch extends NotificationEvent {
  final String recipientId;

  const NotificationEventFetch({required this.recipientId});
}

/// Internal event: stream emitted new data.
class NotificationEventStreamUpdated extends NotificationEvent {
  final List<NotificationModel> notifications;

  const NotificationEventStreamUpdated({required this.notifications});
}

/// Internal event: stream failed.
class NotificationEventStreamError extends NotificationEvent {
  final String message;

  const NotificationEventStreamError({required this.message});
}

/// Fired when user taps a notification (mark as read).
class NotificationEventMarkAsRead extends NotificationEvent {
  final String notificationId;

  const NotificationEventMarkAsRead({required this.notificationId});
}

/// Fired when user taps "Mark all as read".
class NotificationEventMarkAllAsRead extends NotificationEvent {
  final String recipientId;

  const NotificationEventMarkAllAsRead({required this.recipientId});
}
/// Fired when user deletes a single notification.
class NotificationEventDelete extends NotificationEvent {
  final String notificationId;

  const NotificationEventDelete({required this.notificationId});
}

/// Fired when user clears all notifications.
class NotificationEventClearAll extends NotificationEvent {
  final String recipientId;

  const NotificationEventClearAll({required this.recipientId});
}