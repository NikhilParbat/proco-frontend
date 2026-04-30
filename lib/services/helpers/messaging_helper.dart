import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/messaging/send_message.dart';
import 'package:proco/models/response/messaging/messaging_res.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MesssagingHelper {
  static https.Client client = https.Client();

  /// ================= SEND MESSAGE =================
  static Future<Map<String, dynamic>> sendMessage(SendMessage model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {"success": false, "message": "User not authenticated"};
      }

      final url = Config.url(Config.messagingUrl);

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': 'Bearer $token', // ✅ FIXED
        },
        body: jsonEncode(model.toJson()),
      );

      debugPrint("SEND MESSAGE RESPONSE: ${response.body}");

      final decoded = json.decode(response.body);

      if (response.statusCode == 201 && decoded['success'] == true) {
        final message = ReceivedMessage.fromJson(
          decoded['data'] as Map<String, dynamic>,
        );

        return {"success": true, "message": message};
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? "Failed to send message",
        };
      }
    } catch (e) {
      debugPrint("Send Message Error: $e");
      return {"success": false, "message": "Something went wrong"};
    }
  }

  /// ================= GET MESSAGES =================
  static Future<List<ReceivedMessage>> getMessages(
    String chatId,
    int offset,
  ) async {
    try {
      debugPrint('----------FETCHING MESSAGES-------------');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final url = Config.url('${Config.messagingUrl}/$chatId', {
        'page': offset.toString(),
      });

      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );

      debugPrint("GET MESSAGES RESPONSE: ${response.body}");

      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final List data = decoded['data'] ?? [];

        return data
            .map((e) => ReceivedMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load messages');
      }
    } catch (e, s) {
      debugPrint('Error Occurred: -------------- $e ---------------');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
