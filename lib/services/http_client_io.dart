import 'package:http/http.dart' as http;

/// Mobile/desktop: a plain client. Auth is sent via the `token` header.
http.Client buildPlatformClient() => http.Client();
