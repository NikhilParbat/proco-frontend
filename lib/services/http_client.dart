import 'package:http/http.dart' as http;

// Conditional import: pick the web implementation when dart:html is available
// (Flutter web), otherwise the IO implementation (Android/iOS/desktop).
import 'http_client_io.dart'
    if (dart.library.html) 'http_client_web.dart';

/// Returns a platform-appropriate HTTP client.
///
/// Web: a `BrowserClient` with `withCredentials = true`, so the browser
/// automatically attaches the HttpOnly auth cookie to every request. This is
/// what keeps web users logged in across refreshes — the JWT lives only in the
/// cookie (never readable by JavaScript), so XSS cannot steal it.
///
/// Mobile: a standard client. Auth travels in the `token` header, backed by the
/// JWT persisted in SharedPreferences. This path is unchanged.
http.Client createHttpClient() => buildPlatformClient();
