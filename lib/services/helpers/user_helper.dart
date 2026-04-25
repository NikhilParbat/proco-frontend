// ignore_for_file: dead_code

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/auth/profile_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {
  static https.Client client = https.Client();

  /// Returns null on success, or an error description on failure.
  static Future<ApiResponse<UserResponse>> updateProfile(
    ProfileUpdateReq model,
    File? image,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Not authenticated — please log in again.',
        );
      }

      final url = Config.url(Config.profileUrl);
      var request = https.MultipartRequest('PUT', url);

      request.headers['token'] = 'Bearer $token';

      // ✅ Only send non-empty fields
      if (model.username.isNotEmpty) {
        request.fields['username'] = model.username;
      }
      if (model.city.isNotEmpty) request.fields['city'] = model.city;
      if (model.state.isNotEmpty) request.fields['state'] = model.state;
      if (model.country.isNotEmpty) request.fields['country'] = model.country;
      if (model.phone.isNotEmpty) request.fields['phone'] = model.phone;
      if (model.college.isNotEmpty) request.fields['college'] = model.college;
      if (model.branch.isNotEmpty) request.fields['branch'] = model.branch;
      if (model.gender != null) request.fields['gender'] = model.gender!;
      if (model.dob.isNotEmpty) request.fields['dob'] = model.dob;
      if (model.userType.isNotEmpty) {
        request.fields['userType'] = model.userType;
      }
      if (model.linkedInUrl.isNotEmpty) {
        request.fields['linkedInUrl'] = model.linkedInUrl;
      }
      if (model.gitHubUrl.isNotEmpty) {
        request.fields['gitHubUrl'] = model.gitHubUrl;
      }
      if (model.twitterUrl.isNotEmpty) {
        request.fields['twitterUrl'] = model.twitterUrl;
      }
      if (model.portfolioUrl.isNotEmpty) {
        request.fields['portfolioUrl'] = model.portfolioUrl;
      }

      // ✅ Only send location if valid
      if (model.latitude != 0 && model.longitude != 0) {
        request.fields['latitude'] = model.latitude.toString();
        request.fields['longitude'] = model.longitude.toString();
      }

      // ✅ NEW: Send interests, hobbies, skills as JSON arrays
      if (model.skills.isNotEmpty) {
        request.fields['skills'] = jsonEncode(model.skills);
      }
      if (model.interests.isNotEmpty) {
        request.fields['interests'] = jsonEncode(model.interests);
      }
      if (model.hobbies.isNotEmpty) {
        request.fields['hobbies'] = jsonEncode(model.hobbies);
      }

      // ✅ Image
      if (image != null) {
        request.files.add(
          await https.MultipartFile.fromPath('profile', image.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('updateProfile status: ${streamedResponse.statusCode}');
      debugPrint('updateProfile response: $responseBody');

      final decoded = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: decoded['message'],
          data: UserResponse.fromJson(decoded['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: decoded['message'] ?? 'Something went wrong',
      );
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Called once during onboarding to create the user's profile (POST).
  /// Returns null on success, or an error message string on failure.
  static Future<String?> createProfile(
    ProfileUpdateReq model,
    File? image,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      debugPrint('createProfile: token is missing in SharedPreferences');
      return 'Not authenticated — please log in again.';
    }

    final url = Config.url(Config.createProfileUrl);
    var request = https.MultipartRequest('PUT', url);
    request.headers['token'] = 'Bearer $token';

    if (model.username.isNotEmpty) request.fields['username'] = model.username;
    request.fields['city'] = model.city;
    request.fields['state'] = model.state;
    request.fields['country'] = model.country;
    request.fields['phone'] = model.phone;
    request.fields['college'] = model.college;
    request.fields['branch'] = model.branch;
    request.fields['gender'] = model.gender ?? '';
    request.fields['dob'] = model.dob;
    request.fields['userType'] = model.userType;
    request.fields['linkedInUrl'] = model.linkedInUrl;
    request.fields['gitHubUrl'] = model.gitHubUrl;
    request.fields['twitterUrl'] = model.twitterUrl;
    request.fields['portfolioUrl'] = model.portfolioUrl;
    request.fields['latitude'] = model.latitude.toString();
    request.fields['longitude'] = model.longitude.toString();

    // ✅ NEW: Send interests, hobbies, skills
    request.fields['skills'] = jsonEncode(model.skills);
    request.fields['interests'] = jsonEncode(model.interests);
    request.fields['hobbies'] = jsonEncode(model.hobbies);

    if (image != null) {
      request.files.add(
        await https.MultipartFile.fromPath('profile', image.path),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    debugPrint('createProfile status: ${streamedResponse.statusCode}');
    debugPrint('createProfile response: $responseBody');

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final msg = decoded['message'] as String?;
      return '[${streamedResponse.statusCode}] ${msg ?? responseBody}';
    } catch (_) {
      return '[${streamedResponse.statusCode}] $responseBody';
    }
  }

  static Future<ApiResponse<ProfileRes>> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      debugPrint('getProfile: token found, fetching...');

      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'token': 'Bearer $token',
      };

      final url = Config.url('/api/users');
      final response = await client.get(url, headers: requestHeaders);

      debugPrint('getProfile status: ${response.statusCode}');
      debugPrint('getProfile body:   ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: decoded['message'] ?? 'Success',
          data: ProfileRes.fromJson(decoded['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: decoded['message'] ?? 'Failed to fetch profile',
      );
    } catch (e) {
      debugPrint('getProfile error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Fetches a single user's full profile by their userId.
  /// Backend contract: GET /api/users/:userId
  /// Response format: { "success": true, "data": { ...user fields... }
  /// Returns null when the user is not found or a network/parse error occurs.
  static Future<ApiResponse<UserResponse>> fetchUserById(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
      };

      final url = Config.url('${Config.getprofileUrl}$userId');
      final response = await client.get(url, headers: headers);

      debugPrint('fetchUserById [$userId] status: ${response.statusCode}');
      debugPrint('fetchUserById body: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: decoded['message'] ?? 'Success',
          data: UserResponse.fromJson(decoded['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: decoded['message'] ?? 'Failed to fetch user',
      );
    } catch (e) {
      debugPrint('fetchUserById error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<List<SwipedRes>> getUserProfiles(String agentId) async {
    final requestHeaders = {'Content-Type': 'application/json'};
    final url = Config.url('${Config.profileUrl}/$agentId');

    final response = await client.get(url, headers: requestHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isEmpty) {
        debugPrint('No users found for agent: $agentId');
      }

      return data.map((user) => SwipedRes.fromJson(user)).toList();
    } else {
      debugPrint('Failed to load user profiles: ${response.statusCode}');
      throw Exception('Failed to load user profiles');
    }
  }

  static Future<ApiResponse<void>> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Config.url('/api/users');
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Account deleted');
      }
      if (response.body.isNotEmpty) {
        final body = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Failed to delete account',
        );
      }
      return ApiResponse(success: false, message: 'Failed to delete account');
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
