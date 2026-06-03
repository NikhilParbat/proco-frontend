import 'dart:async';

import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:proco/services/config.dart';

/// Web HTTP client. Beyond a plain [BrowserClient] it does two things:
///
/// 1. Sends credentials (the HttpOnly auth cookie) on every request via
///    `withCredentials = true`, and tags itself with the `x-client: web` header
///    so the backend issues the short-lived access token + rotating refresh
///    token flow (instead of the legacy 21-day mobile token).
///
/// 2. Transparently refreshes an expired session. The access cookie lives only
///    15 minutes; once it lapses the backend replies 401 (cookie gone) or 403
///    (JWT expired). This client then calls `POST /api/refresh` exactly once —
///    the browser attaches the long-lived refresh cookie automatically — and,
///    on success, replays the original request with the freshly-minted cookie.
///    A burst of concurrent expired requests shares a single in-flight refresh.
///
/// Without this, web users would be silently logged out 15 minutes after login.
class _WebClient extends http.BaseClient {
  final BrowserClient _inner = BrowserClient()..withCredentials = true;

  /// Single-flight guard: one refresh round-trip serves every request that
  /// hits an expired session at the same time.
  Future<bool>? _refreshing;

  /// Endpoints that must never be retried via refresh — they either establish
  /// the session or are the refresh/logout call itself. A 401/403 here is a
  /// real auth result the caller needs to see.
  static const _authPaths = <String>[
    '/api/login',
    '/api/register',
    '/api/refresh',
    '/api/logout',
    '/api/google-login',
    '/api/google-signup',
    '/api/email-signup',
  ];

  bool _isAuthPath(Uri url) => _authPaths.any((p) => url.path.contains(p));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Buffer the body once so the request can be replayed after a refresh.
    final bodyBytes = await request.finalize().toBytes();

    Future<http.StreamedResponse> attempt() =>
        _inner.send(_rebuild(request, bodyBytes));

    var response = await attempt();

    final expired = response.statusCode == 401 || response.statusCode == 403;
    if (expired && !_isAuthPath(request.url)) {
      final refreshed = await _refreshOnce();
      if (refreshed) {
        await response.stream.drain<void>(); // free the stale response
        response = await attempt();
      }
    }

    return response;
  }

  /// Builds a fresh, sendable request from the buffered bytes, preserving
  /// method, URL and headers, and stamping the web client header. A stale
  /// `content-length` is dropped so http recomputes it from the body.
  http.Request _rebuild(http.BaseRequest original, List<int> bodyBytes) {
    final headers = Map<String, String>.from(original.headers)
      ..remove('content-length');

    final req = http.Request(original.method, original.url)
      ..headers.addAll(headers)
      ..headers['x-client'] = 'web'
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    if (bodyBytes.isNotEmpty) req.bodyBytes = bodyBytes;
    return req;
  }

  Future<bool> _refreshOnce() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    try {
      final req = http.Request('POST', Config.url('/api/refresh'))
        ..headers['Content-Type'] = 'application/json'
        ..headers['x-client'] = 'web';
      final res = await _inner.send(req);
      await res.stream.drain<void>();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void close() => _inner.close();
}

/// Web: a credentialed, self-refreshing client (see [_WebClient]).
http.Client buildPlatformClient() => _WebClient();
