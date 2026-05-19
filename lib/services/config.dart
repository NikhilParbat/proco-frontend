import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static const bool _isProd = false;

  static final String _devHost = kIsWeb
      ? const String.fromEnvironment('LOCAL', defaultValue: 'localhost:3000')
      : dotenv.get('LOCAL');
  static final String _prodHost = kIsWeb
      ? const String.fromEnvironment('DEPLOYMENT', defaultValue: '')
      : dotenv.get('DEPLOYMENT');
  // ─── URI builder ──────────────────────────────────────────────────────────
  // Use this everywhere instead of calling Uri.http / Uri.https directly.
  // It picks the right scheme and host automatically.
  static Uri url(String path, [Map<String, dynamic>? queryParameters]) {
    final host = _isProd ? _prodHost : _devHost;
    return _isProd
        ? Uri.https(host, path, queryParameters)
        : Uri.http(host, path, queryParameters);
  }

  static String socketUrl() {
    final host = _isProd ? _prodHost : _devHost;

    return _isProd ? 'https://$host' : 'http://$host';
  }

  // ─── Paths ────────────────────────────────────────────────────────────────
  static const String loginUrl = '/api/login';
  static const String signupUrl = '/api/register';
  static const String googleLoginUrl = '/api/google-login';
  static const String googleSignupUrl = '/api/google-signup';
  static const String emailSignupUrl = '/api/email-signup';
  static const String jobs = '/api/jobs';
  static const String swipe = '/api/swipes';
  static const String matches = '/api/matches';
  static const String search = '/api/jobs/search';
  static const String job = '/api/jobs';
  static const String profileUrl = '/api/users/update';
  static const String createProfileUrl = '/api/users/update';
  static const String getprofileUrl = '/api/users/';
  static const String bookmarkUrl = '/api/bookmarks';
  static const String chatsUrl = '/api/chats';
  static const String messagingUrl = '/api/messages';
  static const String filters = '/api/filters';
  static const String fcmTokenUrl = '/api/users/fcm-token';
  static const String deviceSessionUrl = '/api/users/device-session';
  static const String deviceSessionsUrl = '/api/users/device-sessions';
}
