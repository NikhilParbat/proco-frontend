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
import 'package:proco/services/token_store.dart';

class UserHelper {
  static https.Client client = https.Client();

  /// Returns null on success, or an error description on failure.
  static Future<ApiResponse<UserResponse>> updateProfile(
    ProfileUpdateReq model,
    File? image,
  ) async {
    try {
      final token = await TokenStore.getToken();

      if (token == null || token.isEmpty) {
        return ApiResponse(success: false, message: 'Not authenticated.');
      }

      final url = Config.url(Config.profileUrl);
      var request = https.MultipartRequest('PUT', url);
      request.headers['token'] = 'Bearer $token';

      // 1. Basic Identity & Contact
      if (model.username.isNotEmpty)
        request.fields['username'] = model.username;
      if (model.phone.isNotEmpty) request.fields['phone'] = model.phone;
      if (model.bio.isNotEmpty) request.fields['bio'] = model.bio;
      if (model.gender != null) request.fields['gender'] = model.gender!;
      if (model.dob.isNotEmpty) request.fields['dob'] = model.dob;
      if (model.userType.isNotEmpty)
        request.fields['userType'] = model.userType;

      // 2. Location & Education
      if (model.city.isNotEmpty) request.fields['city'] = model.city;
      if (model.state.isNotEmpty) request.fields['state'] = model.state;
      if (model.country.isNotEmpty) request.fields['country'] = model.country;
      if (model.workStyle.isNotEmpty)
        request.fields['workStyle'] = model.workStyle;
      if (model.communicationStyle.isNotEmpty)
        request.fields['communicationStyle'] = model.communicationStyle;
      if (model.latitude != 0)
        request.fields['latitude'] = model.latitude.toString();
      if (model.longitude != 0)
        request.fields['longitude'] = model.longitude.toString();

      // 3. Socials
      if (model.linkedInUrl.isNotEmpty)
        request.fields['linkedInUrl'] = model.linkedInUrl;
      if (model.gitHubUrl.isNotEmpty)
        request.fields['gitHubUrl'] = model.gitHubUrl;
      if (model.twitterUrl.isNotEmpty)
        request.fields['twitterUrl'] = model.twitterUrl;
      if (model.portfolioUrl.isNotEmpty)
        request.fields['portfolioUrl'] = model.portfolioUrl;

      // 4 & 5. Attributes + Professional Lists
      _assignJsonListFields(request, model);

      // Education
      if (model.education.isNotEmpty) {
        request.fields['education'] = jsonEncode(
          model.education.map((e) => e.toJson()).toList(),
        );
      }

      // Links
      if (model.links.isNotEmpty) {
        request.fields['links'] = jsonEncode(
          model.links.map((l) => l.toJson()).toList(),
        );
      }

      // 6. Image Upload
      if (image != null) {
        request.files.add(
          await https.MultipartFile.fromPath('profile', image.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
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
        message: decoded['message'] ?? 'Update failed',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Called once during onboarding to create the user's profile (POST).
  /// Returns null on success, or an error message string on failure.
  static Future<String?> createProfile(
    ProfileUpdateReq model,
    File? image,
  ) async {
    try {
      final token = await TokenStore.getToken();

      if (token == null || token.isEmpty) {
        return 'Not authenticated — please log in again.';
      }

      final url = Config.url(Config.createProfileUrl);
      // Using MultipartRequest to handle the profile image
      var request = https.MultipartRequest('PUT', url);
      request.headers['token'] = 'Bearer $token';

      // 1. Basic Identity
      request.fields['username'] = model.username;
      request.fields['phone'] = model.phone;
      request.fields['gender'] = model.gender ?? '';
      request.fields['dob'] = model.dob;
      request.fields['userType'] = model.userType;
      request.fields['bio'] = model.bio;

      // 2. Location & Education
      request.fields['city'] = model.city;
      request.fields['state'] = model.state;
      request.fields['country'] = model.country;
      request.fields['latitude'] = model.latitude.toString();
      request.fields['longitude'] = model.longitude.toString();

      // 3. Socials
      request.fields['linkedInUrl'] = model.linkedInUrl;
      request.fields['gitHubUrl'] = model.gitHubUrl;
      request.fields['twitterUrl'] = model.twitterUrl;
      request.fields['portfolioUrl'] = model.portfolioUrl;

      // 4 & 5. Attributes + Professional Lists
      _assignJsonListFields(request, model);

      // Education
      request.fields['education'] = jsonEncode(
        model.education.map((e) => e.toJson()).toList(),
      );

      // Links
      request.fields['links'] = jsonEncode(
        model.links.map((l) => l.toJson()).toList(),
      );

      // 6. Image
      if (image != null) {
        request.files.add(
          await https.MultipartFile.fromPath('profile', image.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        return null; // Null indicates success
      }

      final decoded = jsonDecode(responseBody);
      return decoded['message'] ?? 'Failed to create profile';
    } catch (e) {
      debugPrint('createProfile error: $e');
      return e.toString();
    }
  }

  static void _assignJsonListFields(
    https.MultipartRequest request,
    ProfileUpdateReq model,
  ) {
    request.fields['skills'] = jsonEncode(model.skills);
    request.fields['interests'] = jsonEncode(model.interests);
    request.fields['hobbies'] = jsonEncode(model.hobbies);
    request.fields['experiences'] = jsonEncode(
      model.experiences.map((e) => e.toJson()).toList(),
    );
    request.fields['projects'] = jsonEncode(
      model.projects.map((p) => p.toJson()).toList(),
    );
    request.fields['achievements'] = jsonEncode(
      model.achievements.map((a) => a.toJson()).toList(),
    );
  }

  static Future<ApiResponse<ProfileRes>> getProfile() async {
    try {
      final token = await TokenStore.getToken();

      if (token == null || token.isEmpty) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'token': 'Bearer $token',
      };

      final url = Config.url('/api/users');
      final response = await client.get(url, headers: requestHeaders);

      // debugPrint('getProfile status: ${response.statusCode}');
      // debugPrint('getProfile body:   ${response.body}');

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
  /// Response format: { "success": true, "data": { ...user fields... } }
  static Future<ApiResponse<UserResponse>> fetchUserById(String userId) async {
    try {
      final token = await TokenStore.getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'token': 'Bearer $token',
      };

      final url = Config.url('${Config.getprofileUrl}$userId');
      final response = await client.get(url, headers: headers);

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
      final token = await TokenStore.getToken();
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
