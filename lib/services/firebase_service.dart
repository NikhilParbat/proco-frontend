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
    // Notification permission and FCM token are intentionally NOT requested here.
    // Requesting at cold start pops the OS permission dialog before the user has
    // done anything (and gets Apple apps rejected under guideline 5.1.1).
    // Permission + token are handled in NotificationHelper.initialize(), which
    // runs from MainScreen only after the user is logged in and in context.
  }
}
