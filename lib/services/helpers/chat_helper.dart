import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/chat/get_chat.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHelper {
  static https.Client client = https.Client();

  /// ================= CREATE CHAT =================
  static Future<Map<String, dynamic>> createChat(CreateChat model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {"success": false, "message": "User not authenticated"};
      }

      final url = Config.url( Config.chatsUrl);

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
        body: jsonEncode(model.toJson()),
      );

      debugPrint("CREATE CHAT RESPONSE: ${response.body}");

      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>?;
        final users =
            (data?['users'] as List?)
                ?.map((u) => u as Map<String, dynamic>)
                .toList() ??
            [];
        return {"success": true, "chatId": data?['_id'] ?? '', "users": users};
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? "Failed to create chat",
        };
      }
    } catch (e) {
      debugPrint("Create Chat Error: $e");
      return {"success": false, "message": "Something went wrong"};
    }
  }

  /// ================= UNMATCH (delete from initiator's side) =================
  static Future<bool> unmatchChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final url = Config.url( '${Config.chatsUrl}/$chatId/unmatch');
      final response = await client.patch(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );

      final decoded = json.decode(response.body);
      return response.statusCode == 200 && decoded['success'] == true;
    } catch (e) {
      debugPrint('UNMATCH CHAT ERROR: $e');
      return false;
    }
  }

  /// ================= CLEAR CHAT (delete all messages) =================
  static Future<bool> clearChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final url = Config.url( '/api/messages/clear/$chatId');
      final response = await client.delete(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );

      final decoded = json.decode(response.body);
      return response.statusCode == 200 && decoded['success'] == true;
    } catch (e) {
      debugPrint('CLEAR CHAT ERROR: $e');
      return false;
    }
  }

  /// ================= TOGGLE PIN CHAT =================
  static Future<bool?> togglePin(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final url = Config.url( '${Config.chatsUrl}/$chatId/pin');
      final response = await client.patch(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );

      final decoded = json.decode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        return decoded['data']['pinned'] as bool;
      }
      return null;
    } catch (e) {
      debugPrint('TOGGLE PIN ERROR: $e');
      return null;
    }
  }

  /// ================= GET CONVERSATIONS =================
  static Future<List<GetChats>> getConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final url = Config.url( Config.chatsUrl);

      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json', 'token': 'Bearer $token'},
      );

      debugPrint("GET CHATS RESPONSE: ${response.body}");

      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final List data = decoded['data'] ?? [];

        return data
            .map((e) => GetChats.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(decoded['message'] ?? "Couldn't load chats");
      }
    } catch (e, s) {
      debugPrint('GET CHATS ERROR: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
