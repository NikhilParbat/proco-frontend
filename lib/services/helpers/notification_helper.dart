import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:proco/constants/app_colors.dart';
import 'package:proco/services/config.dart';
import 'package:proco/services/http_client.dart';
import 'package:proco/services/token_store.dart';
import 'package:proco/views/common/lagoon_snackbar.dart';
import 'package:proco/views/ui/settings/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/services/notification_background.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime time;
  final Map<String, dynamic> data;
  final bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    this.data = const {},
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    title: title,
    body: body,
    time: time,
    data: data,
    isRead: isRead ?? this.isRead,
  );
}

class NotificationHelper {
  static bool _initialized = false;
  static bool _bgHandlerSet = false;
  static final List<NotificationItem> _notifications = [];
  static final List<VoidCallback> _listeners = [];

  // Tab index to jump to when the app opens from a tapped notification:
  // 1 = Chat list, 2 = Bookmarks
  static int? pendingTabIndex;

  static List<NotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  static void markAsRead(int index) {
    if (index < 0 || index >= _notifications.length) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _notifyListeners();
  }

  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  static void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  static Future<void> initialize(String userId, String authToken) async {
    // Prevent duplicate initialization
    if (_initialized) return;

    // 🔥 Firebase protection
    if (Firebase.apps.isEmpty) {
      debugPrint('❌ Firebase not initialized. Skipping notification setup.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Enable Firebase Messaging only when needed
      await messaging.setAutoInitEnabled(true);

      // Background handler
      _setupBackgroundHandler();

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      // First launch only: seed BOTH in-app toggles from the OS permission
      // answer — allow ⇒ both on, deny ⇒ both off. We key off the absence of a
      // stored value so a choice the user later makes in Settings is never
      // overwritten on subsequent launches.
      await _seedPrefsFromPermission(granted);

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ Notification permission denied');
        return;
      }

      // Get FCM token
      final token = await messaging.getToken();

      if (token != null) {
        await _sendTokenToBackend(token, authToken);
      }

      // Token refresh listener
      messaging.onTokenRefresh.listen((newToken) async {
        try {
          await _sendTokenToBackend(newToken, authToken);
        } catch (e) {
          debugPrint('❌ Token refresh backend sync failed: $e');
        }
      });

      // Foreground notifications
      FirebaseMessaging.onMessage.listen((message) async {
        try {
          final prefs = await SharedPreferences.getInstance();

          final type = message.data['type'] ?? '';

          if (type == 'match') {
            final enabled = prefs.getBool(kPrefNotifMatches) ?? true;

            if (!enabled) return;
          } else {
            final enabled = prefs.getBool(kPrefNotifChat) ?? true;

            if (!enabled) return;
          }

          _addFromRemoteMessage(message);

          LagoonSnackbar.show(
            title: message.notification?.title ?? 'New Message',
            message: message.notification?.body ?? '',
          );
        } catch (e) {
          debugPrint('❌ Foreground notification error: $e');
        }
      });

      // Opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        try {
          _addFromRemoteMessage(message);
          _setPendingTab(message);
        } catch (e) {
          debugPrint('❌ onMessageOpenedApp error: $e');
        }
      });

      // Opened from terminated state
      final initial = await messaging.getInitialMessage();

      if (initial != null) {
        try {
          _addFromRemoteMessage(initial);
          _setPendingTab(initial);
        } catch (e) {
          debugPrint('❌ Initial message handling error: $e');
        }
      }

      _initialized = true;

      debugPrint('✅ NotificationHelper initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationHelper initialization failed: $e');

      debugPrint(stackTrace.toString());
    }
  }

  static void _setupBackgroundHandler() {
    if (_bgHandlerSet) return;

    // Background message handling is done via the service worker on web
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    _bgHandlerSet = true;
  }

  static void Function(int)? _tabNavigator;

  /// Call this from MainScreen to wire up live tab switching.
  static void registerTabNavigator(void Function(int) fn) {
    _tabNavigator = fn;
  }

  static void _setPendingTab(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    int? tab;
    if (type == 'chat') tab = 1;
    if (type == 'match') tab = 2;
    if (tab == null) return;

    if (_tabNavigator != null) {
      _tabNavigator!(tab);
    } else {
      pendingTabIndex = tab;
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

  /// Credentialed client: sends the HttpOnly auth cookie on web.
  static final http.Client _prefsClient = createHttpClient();

  /// One-time seeding of the match/chat toggles from the OS permission result.
  /// Runs only when neither preference has been stored yet (true first launch),
  /// so a later manual change in Settings is preserved across app restarts.
  static Future<void> _seedPrefsFromPermission(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySet =
          prefs.containsKey(kPrefNotifMatches) ||
          prefs.containsKey(kPrefNotifChat);
      if (alreadySet) return;

      await prefs.setBool(kPrefNotifMatches, granted);
      await prefs.setBool(kPrefNotifChat, granted);

      // Mirror the seed to the backend so the server-side gate matches the UI
      // from the very first launch.
      await updateNotificationPreferences(
        matchNotifications: granted,
        chatNotifications: granted,
      );
    } catch (e) {
      debugPrint('Seed notification prefs failed: $e');
    }
  }

  /// Persists the user's match/chat notification preferences to the backend so
  /// the server can suppress pushes at the source — the only way a disabled
  /// toggle takes effect when the app is backgrounded or closed. Pass only the
  /// preference(s) being changed; omitted ones are left untouched server-side.
  static Future<bool> updateNotificationPreferences({
    bool? matchNotifications,
    bool? chatNotifications,
  }) async {
    try {
      final token = await TokenStore.getToken() ?? '';
      // Mobile needs a token; web authenticates via the cookie.
      if (!kIsWeb && token.isEmpty) return false;

      final body = <String, dynamic>{};
      if (matchNotifications != null) {
        body['matchNotifications'] = matchNotifications;
      }
      if (chatNotifications != null) {
        body['chatNotifications'] = chatNotifications;
      }
      if (body.isEmpty) return true;

      final response = await _prefsClient.put(
        Config.url(Config.notificationPrefsUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'token': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updateNotificationPreferences error: $e');
      return false;
    }
  }

  static Future<void> _sendTokenToBackend(
    String token,
    String authToken,
  ) async {
    try {
      final url = Config.url(Config.fcmTokenUrl);
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
