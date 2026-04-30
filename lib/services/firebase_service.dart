import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase in isolate (non-blocking)
  static Future<void> initializeAsync() async {
    if (_initialized) return;

    try {
      // ✅ Defer Firebase initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Firebase already initialized in main.dart, just setup messaging
      await _setupMessaging();

      _initialized = true;
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  static Future<void> _setupMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // ✅ Request permissions asynchronously
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // ✅ Get token in background
      messaging
          .getToken()
          .then((token) {
            // debugPrint('FCM Token: $token');
          })
          .catchError((e) {
            debugPrint('FCM Token error: $e');
          });
    } catch (e) {
      debugPrint('Messaging setup error: $e');
    }
  }
}
