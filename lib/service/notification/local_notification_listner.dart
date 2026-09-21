// ============================================================
// LOCAL NOTIFICATION LISTENER
// ============================================================
// Watches the `notifications` collection for new docs aimed at
// the current user and shows a local Android notification.
// This is a stand-in for real push until a server-side sender
// (Cloud Function / OneSignal) is set up.
// ==============

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class LocalNotificationListener {
  static final LocalNotificationListener instance =
      LocalNotificationListener._();
  LocalNotificationListener._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Set<String> _seenIds = {};
  bool _started = false;
  int _counter = 0;

  static const String _channelId = 'forfood_default';
  static const String _channelName = 'ForFood';
  static const String _channelDescription =
      'Order updates, messages and reviews';

  /// Callback for tap → deep-link.
  static void Function(String? type, String? orderId)? onTap;

  // ============================================================
  // START
  // ============================================================
  Future<void> start() async {
    if (_started) return;
    _started = true;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final parts = payload.split('|');
        onTap?.call(
          parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null,
          parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        );
      },
    );

    try {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Channel failed: $e');
    }

    // Watch auth — restart listener when user changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _stopListener();
      } else {
        _startListener(user.uid);
      }
    });
  }

  void _startListener(String uid) {
    _subscription?.cancel();
    _seenIds.clear();

    final cutoff = DateTime.now();

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final doc = change.doc;
          final id = doc.id;

          if (_seenIds.contains(id)) continue;
          _seenIds.add(id);

          final data = doc.data();
          if (data == null) continue;

          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null && createdAt.isBefore(cutoff)) continue;

          _show(
            title: data['title'] as String? ?? 'ForFood',
            body: data['message'] as String? ?? '',
            type: data['type'] as String? ?? '',
            orderId: data['orderId'] as String? ?? '',
          );
        }
      },
      onError: (e) {
        debugPrint('Notification listener error: $e');
      },
    );
  }

  void _stopListener() {
    _subscription?.cancel();
    _subscription = null;
    _seenIds.clear();
  }

  Future<void> _show({
    required String title,
    required String body,
    required String type,
    required String orderId,
  }) async {
    _counter = (_counter + 1) % 100000;

    try {
      await _plugin.show(
        _counter,
        title,
        body,
         NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFE95322),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '$type|$orderId',
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }
}