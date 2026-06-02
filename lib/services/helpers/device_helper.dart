import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as https;
import 'package:proco/services/config.dart';
import 'package:proco/services/http_client.dart';
import 'package:proco/services/token_store.dart';

class DeviceHelper {
  // Shared credentialed client: on web it sends the HttpOnly auth cookie.
  static final https.Client _client = createHttpClient();

  /// Mobile needs a token in the header; web authenticates via the cookie, so a
  /// null/empty in-memory token there is expected (returns false only on mobile).
  static bool _missingAuth(String token) => !kIsWeb && token.isEmpty;

  static Future<bool> registerDeviceSession({
    required String sessionId,
    required String device,
    required String platform,
    required String date,
  }) async {
    try {
      final token = await TokenStore.getToken() ?? '';
      if (_missingAuth(token)) return false;

      final url = Config.url(Config.deviceSessionUrl);
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'token': 'Bearer $token',
        },
        body: jsonEncode({
          'sessionId': sessionId,
          'device': device,
          'platform': platform,
          'date': date,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('registerDeviceSession error: $e');
      return false;
    }
  }

  static Future<bool> removeDeviceSession(String sessionId) async {
    try {
      final token = await TokenStore.getToken() ?? '';
      if (_missingAuth(token)) return false;

      final url = Config.url('${Config.deviceSessionUrl}/$sessionId');
      final response = await _client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'token': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('removeDeviceSession error: $e');
      return false;
    }
  }

  static Future<bool> removeAllDeviceSessions() async {
    try {
      final token = await TokenStore.getToken() ?? '';
      if (_missingAuth(token)) return false;

      final url = Config.url(Config.deviceSessionsUrl);
      final response = await _client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'token': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('removeAllDeviceSessions error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDeviceSessions() async {
    try {
      final token = await TokenStore.getToken() ?? '';
      if (_missingAuth(token)) return [];

      final url = Config.url(Config.deviceSessionsUrl);
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'token': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List<dynamic>? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('fetchDeviceSessions error: $e');
      return [];
    }
  }
}
