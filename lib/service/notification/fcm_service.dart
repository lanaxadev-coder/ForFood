// ============================================================
// FCM SERVICE
// ============================================================
// Single owner of the local-notifications plugin. Creates the
// Android channel, saves the FCM token to Firestore, shows
// foreground pushes, and exposes onNotificationTap for deep-links.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'forfood_default';
  static const String _channelName = 'ForFood';
  static const String _channelDescription =
      'Order updates, messages and reviews';

  int _localNotificationId = 0;
  bool _initialized = false;

  /// Set from main.dart to allow deep-linking when the user taps
  /// a system notification. Signature: (type, orderId).
  static void Function(String? type, String? orderId)? onNotificationTap;

  // ============================================================
  // INITIALIZE
  // ============================================================
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request permission (iOS + Android 13+)
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Init local notifications — the SAME plugin instance
      //    that we'll use for showing messages below.
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

      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          _handlePayload(payload);
        },
      );

      // 3. Create the Android notification channel — on THIS instance
      try {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        );
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      } catch (e) {
        debugPrint('Channel creation failed: $e');
      }

      // 4. Get initial token (best effort — emulators may fail)
      try {
        final token = await _messaging.getToken();
        debugPrint('FCM Token: $token');
      } catch (e) {
        debugPrint('FCM token unavailable: $e');
      }

      // 5. Foreground message → show as local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground push: ${message.notification?.title}');
        _showLocalFromRemote(message);
      });

      // 6. Background tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onNotificationTap?.call(
          message.data['type'] as String?,
          message.data['orderId'] as String?,
        );
      });

      // 7. Cold-start tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          onNotificationTap?.call(
            initialMessage.data['type'] as String?,
            initialMessage.data['orderId'] as String?,
          );
        });
      }

      // 8. Token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'fcmToken': newToken});
        } catch (e) {
          debugPrint('Token refresh failed: $e');
        }
      });

      debugPrint('FCM initialized');
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }

  // ============================================================
  // FOREGROUND DISPLAY
  // ============================================================
  Future<void> _showLocalFromRemote(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    _localNotificationId = (_localNotificationId + 1) % 100000;
    final payload =
        '${message.data['type'] ?? ''}|${message.data['orderId'] ?? ''}';

    try {
      await _local.show(
        _localNotificationId,
        notif.title,
        notif.body,
        const NotificationDetails(
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
        payload: payload,
      );
    } catch (e) {
      debugPrint('Show local notification failed: $e');
    }
  }

  void _handlePayload(String payload) {
    final parts = payload.split('|');
    final type = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
    final orderId =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    onNotificationTap?.call(type, orderId);
  }

  // ============================================================
  // TOKEN
  // ============================================================
  Future<String?> getToken() async => _messaging.getToken();

  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    } catch (e) {
      debugPrint('Save token failed: $e');
    }
  }
}