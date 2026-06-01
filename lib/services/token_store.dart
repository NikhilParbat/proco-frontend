import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-aware session store.
/// Web: keeps token/userId in memory only — never written to localStorage,
///      so XSS cannot steal credentials.
/// Mobile: persists to SharedPreferences (not exposed to JavaScript).
class TokenStore {
  static String? _token;
  static String? _userId;

  static Future<void> saveToken(String token) async {
    _token = token;
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    }
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
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
    }
  }
}
