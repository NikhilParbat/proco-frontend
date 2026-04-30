import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/auth/auth_user_model.dart';
import 'package:proco/models/request/auth/google_auth_model.dart';
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/models/request/auth/signup_model.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/auth/login_res_model.dart';
import 'package:proco/models/response/auth/signup_res_model.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static https.Client client = https.Client();

  static Future<ApiResponse<LoginResponseModel>> login(
    LoginRequestModel model,
  ) async {
    final requestHeaders = {'Content-Type': 'application/json'};
    final url = Config.url(Config.loginUrl);

    final response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model.toJson()),
    );

    debugPrint('Login Response: ${response.body}');

    // ✅ Handle empty response (cold start)
    if (response.body.isEmpty) {
      return ApiResponse(
        success: false,
        message: 'Server is starting up, please try again',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // ✅ Parse ONLY data
      final user = LoginResponseModel.fromJson(body['data']);

      // ✅ Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', user.userToken);
      await prefs.setString('userId', user.id);
      await prefs.setBool('onboardingComplete', !(user.isFirstTimeUser));

      return ApiResponse(
        success: true,
        message: body['message'] ?? 'Login successful',
        data: user,
      );
    } else {
      return ApiResponse(
        success: false,
        message: body['message'] ?? 'An error occurred',
      );
    }
  }

  static Future<ApiResponse<SignupResponseModel>> signup(
    SignupRequestModel model,
  ) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};

      final url = Config.url(Config.signupUrl);

      final response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(model.toJson()), // ✅ FIXED
      );

      debugPrint('Signup Response: ${response.body}');

      // ✅ Handle empty response
      if (response.body.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Server is starting up, please try again',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final signupData = SignupResponseModel.fromJson(body['data']);

        return ApiResponse(
          success: true,
          message: body['message'] ?? 'User created successfully',
          data: signupData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'An error occurred',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Google Sign-In API call
  static Future<ApiResponse<AuthUserModel>> googleLogin(
    GoogleAuthModel model,
  ) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};

      final url = Config.url(Config.googleLoginUrl);

      final response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(model.toJson()),
      );

      // ✅ Handle empty response
      if (response.body.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Server is starting up, please try again',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final user = AuthUserModel.fromJson(body['data']);

        final prefs = await SharedPreferences.getInstance();

        if (user.userToken != null) {
          await prefs.setString('token', user.userToken!);
        }

        if (user.id != null) {
          await prefs.setString('userId', user.id!);
        }

        if (body['data']?['profile'] != null) {
          await prefs.setString('profile', body['data']['profile']);
        }

        await prefs.setBool(
          'onboardingComplete',
          !(user.isFirstTimeUser ?? false),
        );

        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Login successful',
          data: user,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Google login failed',
        );
      }
    } catch (e) {
      debugPrint('Google login error: $e');

      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Called after Firebase email verification is confirmed.
  /// Registers the user in the backend with just email + username.
  static Future<ApiResponse<AuthUserModel>> emailSignup({
    required String idToken,
    required String email,
    required String username,
  }) async {
    try {
      final requestHeaders = {'Content-Type': 'application/json'};

      final url = Config.url(Config.emailSignupUrl);

      final response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode({
          'idToken': idToken,
          'email': email,
          'displayName': username,
        }),
      );

      debugPrint('Email Signup Response: ${response.body}');

      // ✅ Handle empty response
      if (response.body.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Server is starting up, please try again',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = AuthUserModel.fromJson(body['data']);

        // ✅ Save session
        final prefs = await SharedPreferences.getInstance();

        if (user.userToken != null) {
          await prefs.setString('token', user.userToken!);
        }

        if (user.id != null) {
          await prefs.setString('userId', user.id!);
        }

        await prefs.setBool('loggedIn', true);

        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Signup successful',
          data: user,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Sign up failed',
        );
      }
    } catch (e) {
      debugPrint('Email signup error: $e');

      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<AuthUserModel>> googleSignup(
    GoogleAuthModel model,
  ) async {
    try {
      final url = Config.url(Config.googleSignupUrl);

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(model.toJson()), // ✅ CLEAN
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = AuthUserModel.fromJson(data['data']);

        final prefs = await SharedPreferences.getInstance();
        if (user.userToken != null) {
          await prefs.setString('token', user.userToken!);
        }
        if (user.id != null) {
          await prefs.setString('userId', user.id!);
        }

        return ApiResponse(
          success: true,
          message: data['message'] ?? 'Signup successful',
          data: user,
        );
      } else {
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
