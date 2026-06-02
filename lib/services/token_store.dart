import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-aware session store.
/// Web: keeps token/userId in memory only — never written to localStorage,
///      so XSS cannot steal credentials.
/// Mobile: persists to SharedPreferences (not exposed to JavaScript).
class TokenStore {
  static String? _token;
  static String? _userId;

  /// Non-sensitive flag persisted on web so startup can decide "is a session
  /// active?" instantly, without waiting on a network call. This is NOT the
  /// JWT (that stays in the HttpOnly cookie) — just a boolean. Worst case an
  /// attacker flips it, but with no valid cookie every API call still 401s.
  static const String _webSessionKey = 'webSession';

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await prefs.setBool(_webSessionKey, true);
    } else {
      await prefs.setString('token', token);
    }
  }

  /// Web only: has a session been established (cookie present)? Read instantly
  /// at startup; the cookie is then validated lazily by the first API call.
  static Future<bool> hasWebSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_webSessionKey) ?? false;
  }

  static Future<void> saveUserId(String userId) async {
    _userId = userId;
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUserId() async {
    if (kIsWeb) return _userId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<void> clear() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await prefs.remove(_webSessionKey);
    } else {
      await prefs.remove('token');
      await prefs.remove('userId');
    }
  }
}
