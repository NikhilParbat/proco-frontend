import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:proco/constants/app_constants.dart';
import 'package:proco/services/config.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime time;
  final Map<String, dynamic> data;

  NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    this.data = const {},
  });
}

class NotificationHelper {
  static final List<NotificationItem> _notifications = [];
  static final List<VoidCallback> _listeners = [];

  static List<NotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  static void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  static Future<void> initialize(String userId, String authToken) async {
    final messaging = FirebaseMessaging.instance;

    // Request OS-level permission (required on iOS and Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get device FCM token and register it with backend
    final token = await messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(token, authToken);
    }

    // Re-register if token rotates
    messaging.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken, authToken);
    });

    // Foreground: show in-app snackbar + add to notification list
    FirebaseMessaging.onMessage.listen((message) {
      _addFromRemoteMessage(message);
      Get.snackbar(
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? '',
        colorText: kLight,
        backgroundColor: kLightBlue,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.notifications, color: Colors.white),
      );
    });

    // App brought to foreground by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _addFromRemoteMessage(message);
    });

    // Check if app was opened from a terminated-state notification
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _addFromRemoteMessage(initial);
    }
  }

  static void _addFromRemoteMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    if (title.isEmpty && body.isEmpty) return;

    _notifications.insert(
      0,
      NotificationItem(
        title: title,
        body: body,
        time: DateTime.now(),
        data: Map<String, dynamic>.from(message.data),
      ),
    );
    _notifyListeners();
  }

  static Future<void> _sendTokenToBackend(
    String token,
    String authToken,
  ) async {
    try {
      final url = Config.url( Config.fcmTokenUrl);
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }
}
