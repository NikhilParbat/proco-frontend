import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/filters/create_filter.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/filters/filter_response.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterHelper {
  static https.Client client = https.Client();

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
    };
  }

  static Future<ApiResponse<List<FilterResponse>>> getFilters() async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.filters);
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Filters fetched successfully',
          data: filterResponseFromJson(response.body),
        );
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to get filters');
      }
    } catch (e) {
      debugPrint('FilterHelper.getFilters error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // GET /api/filters/:agentId — returns the single filter for this user
  static Future<ApiResponse<GetFilterRes>> getFilter(String agentId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.filters}/$agentId');
      final response = await client.get(url, headers: headers);

      debugPrint('getFilter url: $url');
      debugPrint('getFilter status: ${response.statusCode}');
      debugPrint('getFilter body: ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Filter fetched successfully',
          data: getFilterResFromJson(response.body),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'No filter found');
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to get filter');
      }
    } catch (e) {
      debugPrint('FilterHelper.getFilter error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // POST /api/filters — create or upsert filter
  static Future<ApiResponse<GetFilterRes>> createFilter(CreateFilterRequest model) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.filters);
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(model.toJson()),
      );

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: 'Filter saved successfully',
          data: getFilterResFromJson(response.body),
        );
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to save filter');
      }
    } catch (e) {
      debugPrint('FilterHelper.createFilter error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // PUT /api/filters/:id — update by filter id
  static Future<ApiResponse<void>> updateFilter(
    String filterId,
    Map<String, dynamic> filterData,
  ) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.filters}/$filterId');
      final response = await client.put(
        url,
        headers: headers,
        body: jsonEncode(filterData),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Filter updated successfully');
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to update filter');
      }
    } catch (e) {
      debugPrint('FilterHelper.updateFilter error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // DELETE /api/filters/:id
  static Future<ApiResponse<void>> deleteFilter(String filterId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.filters}/$filterId');
      final response = await client.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Filter deleted successfully');
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to delete filter');
      }
    } catch (e) {
      debugPrint('FilterHelper.deleteFilter error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
