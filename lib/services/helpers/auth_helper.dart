import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as https;
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/models/request/auth/signup_model.dart';
import 'package:proco/models/response/auth/login_res_model.dart';
import 'package:proco/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static https.Client client = https.Client();

  static Future<List<dynamic>> login(LoginModel model) async {
    final requestHeaders = <String, String>{'Content-Type': 'application/json'};
    final url = Config.url( Config.loginUrl);

    final response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model),
    );

    debugPrint('Login Response: ${response.body}');

    // ✅ Guard against empty body (Render cold start)
    if (response.body.isEmpty) {
      return [false, 'Server is starting up, please try again'];
    }

    // ✅ Parse once, read fields directly — no ErrorRes model needed
    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final loginRes = loginResponseModelFromJson(response.body);

      await prefs.setString('token', loginRes.userToken);
      await prefs.setString('userId', loginRes.id);
      await prefs.setString('profile', loginRes.profile);

      // Use the flag returned by the backend to decide onboarding state.
      // isFirstTimeUser: true means the account needs to complete onboarding.
      final isFirstTimeUser = body['data']?['isFirstTimeUser'] as bool? ?? false;
      await prefs.setBool('onboardingComplete', !isFirstTimeUser);

      return [true, isFirstTimeUser];
    } else {
      // ✅ Server always sends { success: false, message: "..." }
      final message = body['message'] as String? ?? 'An error occurred';
      return [false, message];
    }
  }

  static Future<List<dynamic>> signup(SignupModel model) async {
    try {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
      };
      final url = Config.url( Config.signupUrl);

      debugPrint(jsonEncode(model));

      final response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(model),
      );

      if (response.body.isEmpty) {
        return [false, 'Server is starting up, please try again'];
      }

      if (response.statusCode == 201) {
        return [true];
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final message = body['message'] as String? ?? 'An error occurred';
        return [false, message];
      }
    } catch (e) {
      return [false, e.toString()];
    }
  }

  // Google Sign-In API call
  static Future<List<dynamic>> googleLogin({
    required String idToken,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
      };
      final url = Config.url( Config.googleLoginUrl);

      final response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode({
          'idToken': idToken,
          'email': email,
          'displayName': displayName,
        }),
      );

      debugPrint('Google Login Response: ${response.body}');

      if (response.body.isEmpty) {
        return [false, 'Server is starting up, please try again'];
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        final data = body['data'];
        await prefs.setString('token', data['userToken']);
        await prefs.setString('userId', data['_id']);
        await prefs.setString('profile', data['profile'] ?? '');

        // If the backend flags this as a first-time user (e.g. re-signup after
        // account deletion), onboarding has NOT been completed yet.
        final isFirstTimeUser = data['isFirstTimeUser'] as bool? ?? false;
        await prefs.setBool('onboardingComplete', !isFirstTimeUser);

        return [true, isFirstTimeUser];
      } else {
        final message = body['message'] as String? ?? 'Google login failed';
        return [false, message];
      }
    } catch (e) {
      debugPrint('Google login error: $e');
      return [false, 'Connection error: ${e.toString()}'];
    }
  }

  /// Called after Firebase email verification is confirmed.
  /// Registers the user in the backend with just email + username.
  static Future<List<dynamic>> emailSignup({
    required String idToken,
    required String email,
    required String username,
  }) async {
    try {
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
      };
      final url = Config.url( Config.emailSignupUrl);

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

      if (response.body.isEmpty) {
        return [false, 'Server is starting up, please try again'];
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final data = body['data'];
        if (data?['userToken'] != null) {
          await prefs.setString('token', data['userToken']);
        }
        if (data?['_id'] != null) {
          await prefs.setString('userId', data['_id']);
        }
        await prefs.setBool('loggedIn', true);
        return [true];
      } else {
        final message = body['message'] as String? ?? 'Sign up failed';
        return [false, message];
      }
    } catch (e) {
      debugPrint('Email signup error: $e');
      return [false, 'Connection error: ${e.toString()}'];
    }
  }

  static Future<List<dynamic>> googleSignup({
    required String idToken,
    required String email,
    String? displayName,
    String? photoURL,
    double? latitude,
    double? longitude,
  }) async {
    try {
      var url = Config.url( Config.googleSignupUrl);

      final body = {
        'idToken': idToken,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
      };

      // Add location if available
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude.toString();
        body['longitude'] = longitude.toString();
      }

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'] ?? {};

        final prefs = await SharedPreferences.getInstance();
        if (userData['userToken'] != null) {
          await prefs.setString('token', userData['userToken']);
        }
        if (userData['_id'] != null) {
          await prefs.setString('userId', userData['_id']);
        }
        if (userData['profile'] != null) {
          await prefs.setString('profile', userData['profile']);
        }

        // isFirstTimeUser: true  → new account, must go through onboarding
        // isFirstTimeUser: false → existing email/password account linked via Google,
        //                          onboarding already complete
        final isFirstTimeUser = userData['isFirstTimeUser'] as bool? ?? true;
        await prefs.setBool('onboardingComplete', !isFirstTimeUser);

        return [true, isFirstTimeUser];
      } else {
        var error = jsonDecode(response.body);
        return [false, error['message'] ?? 'Signup failed'];
      }
    } catch (e) {
      return [false, e.toString()];
    }
  }
}
