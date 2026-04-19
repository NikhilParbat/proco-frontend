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
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to get filter');
      }
    } catch (e) {
      debugPrint('FilterHelper.getFilter error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<ApiResponse<List<FilterResponse>>> getUserFilters(String agentId) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url('${Config.filters}/$agentId');
      final response = await client.get(url, headers: headers);

      debugPrint('getUserFilters url: $url');
      debugPrint('getUserFilters status: ${response.statusCode}');
      debugPrint('getUserFilters body: ${response.body}');

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<FilterResponse> filters;

        if (data['data'] is List) {
          filters = (data['data'] as List)
              .map((f) => FilterResponse.fromJson(f as Map<String, dynamic>))
              .toList();
        } else if (data['data'] is Map) {
          filters = [FilterResponse.fromJson(data['data'] as Map<String, dynamic>)];
        } else {
          return ApiResponse(success: false, message: 'Unexpected response structure');
        }

        return ApiResponse(
          success: true,
          message: 'User filters fetched successfully',
          data: filters,
        );
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to load user filters');
      }
    } catch (e) {
      debugPrint('FilterHelper.getUserFilters error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<ApiResponse<FilterResponse>> getRecentFilters() async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.filters, {'new': 'true'});
      final response = await client.get(url, headers: headers);

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200) {
        final list = filterResponseFromJson(response.body);
        if (list.isEmpty) {
          return ApiResponse(success: false, message: 'No recent filters found');
        }
        return ApiResponse(
          success: true,
          message: 'Recent filter fetched successfully',
          data: list.first,
        );
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to get recent filters');
      }
    } catch (e) {
      debugPrint('FilterHelper.getRecentFilters error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<ApiResponse<FilterResponse>> createFilter(CreateFilterRequest model) async {
    try {
      final headers = await _authHeaders();
      final url = Config.url(Config.filters);
      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(model),
      );

      if (response.body.isEmpty) {
        return ApiResponse(success: false, message: 'Server is starting up, please try again');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Filter created successfully',
          data: FilterResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        final body = jsonDecode(response.body);
        return ApiResponse(success: false, message: body['message'] ?? 'Failed to create filter');
      }
    } catch (e) {
      debugPrint('FilterHelper.createFilter error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

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
