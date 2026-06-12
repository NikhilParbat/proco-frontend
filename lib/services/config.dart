import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static const bool _isProd = true;

  /// Hardcoded production host used as a fallback when the `.env` file is
  /// missing or doesn't contain the key. This guarantees the app can always
  /// reach the backend even if asset loading failed — preventing the
  /// "everything fails to load" class of bugs.
  static const String _fallbackProdHost = 'proco-backend-n5so.onrender.com';
  static const String _fallbackDevHost = '10.0.2.2:3000';

  /// Reads a key from dotenv without ever throwing. Returns [fallback] if the
  /// key is absent, empty, or dotenv failed to initialise.
  static String _envOr(String key, String fallback) {
    try {
      final value = dotenv.maybeGet(key);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {}
    return fallback;
  }

  static final String _devHost = kIsWeb
      ? const String.fromEnvironment('LOCAL', defaultValue: _fallbackDevHost)
      : _envOr('LOCAL', _fallbackDevHost);
  static final String _prodHost = kIsWeb
      ? const String.fromEnvironment(
          'DEPLOYMENT',
          defaultValue: _fallbackProdHost,
        )
      : _envOr('DEPLOYMENT', _fallbackProdHost);
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

  /// Public URL of the deployed Flutter web app. Shared opportunity links
  /// point here so anyone (no install, not logged in) can open them in a
  /// browser.
  static const String webAppBase = 'https://lagoon-web.onrender.com';

  /// Public, shareable link to a single opportunity. The id is passed as a
  /// query parameter on the web app root — this needs zero hosting/route
  /// config (no rewrites, no GetX named routes) and is read back on startup
  /// via [sharedOpportunityId].
  static String opportunityShareUrl(String id) =>
      '$webAppBase/?opportunity=$id';

  /// Reads the shared opportunity id from a launch URL (the browser address on
  /// web). Returns null when this isn't a shared-opportunity launch.
  static String? sharedOpportunityId(Uri uri) {
    final id = uri.queryParameters['opportunity'];
    return (id != null && id.isNotEmpty) ? id : null;
  }

  // ─── Shared-opportunity call-to-action ────────────────────────────────────
  // The persistent prompt on the public shared-opportunity view. Today it
  // invites the viewer into the web app. Once the native app is published,
  // flip [appStoreLive] to true and fill the store URLs below — that's the
  // only change needed (see ShareCtaBar in opportunity_share_screen.dart).
  static const bool appStoreLive = false;
  static const String playStoreUrl = '';
  static const String appStoreUrl = '';

  // ─── Paths ────────────────────────────────────────────────────────────────
  static const String loginUrl = '/api/login';
  static const String signupUrl = '/api/register';
  static const String googleLoginUrl = '/api/google-login';
  static const String googleSignupUrl = '/api/google-signup';
  static const String emailSignupUrl = '/api/email-signup';
  static const String resendVerificationUrl = '/api/resend-verification';
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
  static const String notificationPrefsUrl = '/api/users/notification-preferences';
  static const String deviceSessionUrl = '/api/users/device-session';
  static const String deviceSessionsUrl = '/api/users/device-sessions';
}
