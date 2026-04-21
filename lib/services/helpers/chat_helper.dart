import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/chat/get_chat.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHelper {
  static https.Client client = https.Client();

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
    };
  }

  /// POST /api/chats — access or create a 1-1 chat, returns chatId
  static Future<ApiResponse<String>> createChat(CreateChat model) async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('token')) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final url = Config.url(Config.chatsUrl);
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(model.toJson()),
      );

      debugPrint('createChat status: ${response.statusCode}');
      debugPrint('createChat body:   ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final chatId = decoded['data']?['chatId'] as String? ?? '';
        return ApiResponse(success: true, message: 'Chat ready', data: chatId);
      } else {
        return ApiResponse(success: false, message: decoded['message'] ?? 'Failed to access chat');
      }
    } catch (e) {
      debugPrint('ChatHelper.createChat error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// GET /api/chats — get all chats for current user
  static Future<ApiResponse<List<GetChats>>> getConversations() async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('token')) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final url = Config.url(Config.chatsUrl);
      final response = await client.get(url, headers: headers);

      debugPrint('getConversations status: ${response.statusCode}');
      debugPrint('getConversations body:   ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final List data = decoded['data'] ?? [];
        final chats = data
            .map((e) => GetChats.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, message: decoded['message'] ?? '', data: chats);
      } else {
        return ApiResponse(success: false, message: decoded['message'] ?? 'Failed to load chats');
      }
    } catch (e) {
      debugPrint('ChatHelper.getConversations error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// PATCH /api/chats/:id/unmatch
  static Future<ApiResponse<void>> unmatchChat(String chatId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.chatsUrl}/$chatId/unmatch');
      final response = await client.patch(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        return ApiResponse(success: true, message: 'Unmatched successfully');
      }
      return ApiResponse(success: false, message: decoded['message'] ?? 'Failed to unmatch');
    } catch (e) {
      debugPrint('ChatHelper.unmatchChat error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// DELETE /api/messages/clear/:chatId
  static Future<ApiResponse<void>> clearChat(String chatId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('/api/messages/clear/$chatId');
      final response = await client.delete(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        return ApiResponse(success: true, message: 'Chat cleared');
      }
      return ApiResponse(success: false, message: decoded['message'] ?? 'Failed to clear chat');
    } catch (e) {
      debugPrint('ChatHelper.clearChat error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// PATCH /api/chats/:id/pin — returns new pin state
  static Future<ApiResponse<bool>> togglePin(String chatId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.chatsUrl}/$chatId/pin');
      final response = await client.patch(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        final pinned = decoded['data']?['pinned'] as bool? ?? false;
        return ApiResponse(success: true, message: 'Pin updated', data: pinned);
      }
      return ApiResponse(success: false, message: decoded['message'] ?? 'Failed to update pin');
    } catch (e) {
      debugPrint('ChatHelper.togglePin error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
