import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as client;
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceHelper {
  static Future<bool> registerDeviceSession({
    required String sessionId,
    required String device,
    required String platform,
    required String date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final url = Config.url(Config.deviceSessionUrl);
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final url = Config.url('${Config.deviceSessionUrl}/$sessionId');
      final response = await client.delete(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('removeDeviceSession error: $e');
      return false;
    }
  }

  static Future<bool> removeAllDeviceSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final url = Config.url(Config.deviceSessionsUrl);
      final response = await client.delete(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('removeAllDeviceSessions error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDeviceSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final url = Config.url(Config.deviceSessionsUrl);
      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
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
