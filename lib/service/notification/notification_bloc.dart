// ============================================================
// NOTIFICATION BLOC — PRODUCTION READY (NO TIMEOUT HACK)
// ============================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/notification_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/notification/notification_event.dart';
import 'package:forfood/service/notification/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FirestoreProvider _firestoreProvider;
  StreamSubscription<List<NotificationModel>>? _subscription;

  NotificationBloc(FirestoreProvider firestoreProvider)
      : _firestoreProvider = firestoreProvider,
        super(const NotificationStateInitial()) {
    on<NotificationEventCreate>(_onCreate);
    on<NotificationEventFetch>(_onFetch);
    on<NotificationEventStreamUpdated>(_onStreamUpdated);
    on<NotificationEventStreamError>(_onStreamError);
    on<NotificationEventMarkAsRead>(_onMarkAsRead);
    on<NotificationEventMarkAllAsRead>(_onMarkAllAsRead);
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> _onCreate(
    NotificationEventCreate event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _firestoreProvider.createNotification(event.notification);
    } on FirestoreOperationException catch (e) {
      emit(NotificationStateError(message: e.message));
    }
  }

  // ============================================================
  // FETCH (STREAM)
  // ============================================================

  Future<void> _onFetch(
    NotificationEventFetch event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationStateLoading());

    await _subscription?.cancel();

    _subscription = _firestoreProvider
        .streamNotificationsByRecipientId(event.recipientId)
        .listen(
      (notifications) {
        if (!isClosed) {
          add(NotificationEventStreamUpdated(notifications: notifications));
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(NotificationEventStreamError(message: error.toString()));
        }
      },
    );
  }

  // ============================================================
  // INTERNAL STREAM HANDLERS
  // ============================================================

  void _onStreamUpdated(
    NotificationEventStreamUpdated event,
    Emitter<NotificationState> emit,
  ) {
    final unreadCount = event.notifications.where((n) => !n.isRead).length;
    emit(NotificationStateLoaded(
      notifications: event.notifications,
      unreadCount: unreadCount,
    ));
  }

  void _onStreamError(
    NotificationEventStreamError event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationStateError(message: event.message));
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> _onMarkAsRead(
    NotificationEventMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _firestoreProvider.markNotificationAsRead(event.notificationId);
    } on FirestoreOperationException catch (e) {
      emit(NotificationStateError(message: e.message));
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _onMarkAllAsRead(
    NotificationEventMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _firestoreProvider.markAllNotificationsAsRead(event.recipientId);
    } on FirestoreOperationException catch (e) {
      emit(NotificationStateError(message: e.message));
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}