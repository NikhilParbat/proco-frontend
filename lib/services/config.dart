class Config {
  // ─── Environment toggle ───────────────────────────────────────────────────
  // Set _isProd = false when running on an emulator (local Node server).
  // Set _isProd = true  when building an APK / release build (Render.com).
  static const bool _isProd = true;

  // ─── API hosts (no scheme, no trailing slash) ─────────────────────────────
  static const String _devHost  = '10.0.2.2:3000';
  static const String _prodHost = 'proco-server-api.onrender.com';

  // ─── URI builder ──────────────────────────────────────────────────────────
  // Use this everywhere instead of calling Uri.http / Uri.https directly.
  // It picks the right scheme and host automatically.
  static Uri url(String path, [Map<String, dynamic>? queryParameters]) {
    final host = _isProd ? _prodHost : _devHost;
    return _isProd
        ? Uri.https(host, path, queryParameters)
        : Uri.http(host, path, queryParameters);
  }

  // ─── Paths ────────────────────────────────────────────────────────────────
  static const String loginUrl       = '/api/login';
  static const String signupUrl      = '/api/register';
  static const String googleLoginUrl = '/api/google-login';
  static const String googleSignupUrl = '/api/google-signup';
  static const String emailSignupUrl  = '/api/email-signup';
  static const String jobs           = '/api/jobs';
  static const String swipe          = '/api/swipes';
  static const String matches        = '/api/matches';
  static const String search         = '/api/jobs/search';
  static const String job            = '/api/jobs';
  static const String profileUrl     = '/api/users/update';
  static const String getprofileUrl  = '/api/users/';
  static const String bookmarkUrl    = '/api/bookmarks';
  static const String chatsUrl       = '/api/chats';
  static const String messagingUrl   = '/api/messages';
  static const String filters        = '/api/filters';
  static const String fcmTokenUrl    = '/api/users/fcm-token';
}
