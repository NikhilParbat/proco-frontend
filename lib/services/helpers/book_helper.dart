import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/bookmarks/bookmarks_model.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookMarkHelper {
  static https.Client client = https.Client();

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
    };
  }

  /// ================= ADD BOOKMARK =================
  static Future<ApiResponse<void>> addBookmarks(
    BookmarkReqResModel model,
  ) async {
    try {
      final headers = await _authHeaders();

      if (!headers.containsKey('token')) {
        return ApiResponse(success: false, message: 'Not authenticated — please log in again.');
      }

      final url = Config.url(Config.bookmarkUrl);

      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(model.toJson()),
      );

      debugPrint('addBookmarks status: ${response.statusCode}');
      debugPrint('addBookmarks body:   ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again.');
      }

      final decoded = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          decoded['success'] == true) {
        return ApiResponse(
          success: true,
          message: decoded['message'] ?? 'Bookmark added successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'Failed to add bookmark',
        );
      }
    } catch (e) {
      debugPrint('BookMarkHelper.addBookmarks error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// ================= DELETE BOOKMARK =================
  static Future<ApiResponse<void>> deleteBookmarks(String jobId) async {
    try {
      final headers = await _authHeaders();

      if (!headers.containsKey('token')) {
        return ApiResponse(success: false, message: 'Not authenticated — please log in again.');
      }

      final url = Config.url('${Config.bookmarkUrl}/$jobId');

      final response = await client.delete(url, headers: headers);

      debugPrint('deleteBookmarks status: ${response.statusCode}');
      debugPrint('deleteBookmarks body:   ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again.');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return ApiResponse(
          success: true,
          message: decoded['message'] ?? 'Bookmark deleted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'Failed to delete bookmark',
        );
      }
    } catch (e) {
      debugPrint('BookMarkHelper.deleteBookmarks error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// ================= GET ALL BOOKMARKS =================
  static Future<ApiResponse<List<AllBookmark>>> getBookmarks() async {
    try {
      final headers = await _authHeaders();

      if (!headers.containsKey('token')) {
        return ApiResponse(success: false, message: 'Not authenticated — please log in again.');
      }

      final url = Config.url(Config.bookmarkUrl);

      final response = await client.get(url, headers: headers);

      debugPrint('getBookmarks status: ${response.statusCode}');
      debugPrint('getBookmarks body:   ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again.');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final List data = decoded['data'] ?? [];

        // Guard against orphaned bookmarks where the job was deleted
        final bookmarks = data
            .where((e) => e is Map && e['jobId'] != null)
            .map((e) => AllBookmark.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          message: decoded['message'] ?? 'Bookmarks fetched successfully',
          data: bookmarks,
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'Failed to load bookmarks',
        );
      }
    } catch (e) {
      debugPrint('BookMarkHelper.getBookmarks error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
