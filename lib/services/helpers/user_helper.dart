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
  static Future<String?> updateProfile(ProfileUpdateReq model, File? image) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      debugPrint('updateProfile: token is missing in SharedPreferences');
      return 'Not authenticated — please log in again.';
    }

    final url = Config.url( Config.profileUrl);

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

    final url = Config.url( '/api/users');
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

  static Future<List<SwipedRes>> getUserProfiles(String agentId) async {
    final requestHeaders = {'Content-Type': 'application/json'};
    final url = Config.url( '${Config.profileUrl}/$agentId');

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
