// ignore_for_file: dead_code

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/models/response/auth/profile_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {
  static https.Client client = https.Client();

  /// Returns null on success, or an error description on failure.
  static Future<String?> updateProfile(
    ProfileUpdateReq model,
    File? image,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      debugPrint('updateProfile: token is missing in SharedPreferences');
      return 'Not authenticated — please log in again.';
    }

    final url = Config.url(Config.profileUrl);

    var request = https.MultipartRequest('PUT', url);

    request.headers['token'] = 'Bearer $token';

    // ✅ Add text fields
    if (model.name.isNotEmpty) request.fields['username'] = model.name;
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

    // if skills is list
    request.fields['skills'] = jsonEncode(model.skills);

    // ✅ Add image file
    if (image != null) {
      request.files.add(
        await https.MultipartFile.fromPath(
          'profile', // MUST match backend multer field
          image.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    debugPrint('updateProfile status: ${streamedResponse.statusCode}');
    debugPrint('updateProfile body:   $responseBody');

    if (streamedResponse.statusCode == 200) return null;

    // Extract backend message for a useful error snackbar
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final msg = decoded['message'] as String?;
      return '[${streamedResponse.statusCode}] ${msg ?? responseBody}';
    } catch (_) {
      return '[${streamedResponse.statusCode}] $responseBody';
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

    if (model.name.isNotEmpty) request.fields['username'] = model.name;
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
    request.fields['skills'] = jsonEncode(model.skills);

    if (image != null) {
      request.files.add(
        await https.MultipartFile.fromPath('profile', image.path),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201)
      return null;

    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final msg = decoded['message'] as String?;
      return '[${streamedResponse.statusCode}] ${msg ?? responseBody}';
    } catch (_) {
      return '[${streamedResponse.statusCode}] $responseBody';
    }
  }

  static Future<ProfileRes?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      debugPrint('getProfile: token missing in SharedPreferences');
      return null;
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

    if (response.statusCode == 200) {
      final profile = profileResFromJson(response.body);
      return profile;
    } else {
      throw Exception(
        'Profile fetch failed [${response.statusCode}]: ${response.body}',
      );
    }
  }

  // ─── Device Session API ───────────────────────────────────────────────────

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

  /// Fetches a single user's full profile by their userId.
  ///
  /// Backend contract: GET /api/users/:userId
  /// Response format: { "success": true, "data": { ...user fields... } }
  ///
  /// Returns null when the user is not found or a network/parse error occurs.
  static Future<ProfileRes?> fetchUserById(String userId) async {
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

      if (response.statusCode == 200) {
        return profileResFromJson(response.body);
      }

      debugPrint('fetchUserById failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('fetchUserById error: $e');
      return null;
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
}
