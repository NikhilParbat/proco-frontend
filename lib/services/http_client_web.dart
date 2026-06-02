import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Web: a BrowserClient that sends credentials (the HttpOnly auth cookie) with
/// every cross-origin request. Without `withCredentials = true` the browser
/// would never attach the cookie, so the server could not authenticate the
/// request and the user would appear logged out after a refresh.
http.Client buildPlatformClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
