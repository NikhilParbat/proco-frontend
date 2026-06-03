import 'dart:async';
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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:proco/services/config.dart';
import 'package:proco/services/http_client.dart';
import 'package:proco/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static https.Client client = createHttpClient();

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

      // Credentials go through TokenStore only: in-memory on web (never
      // written to localStorage), SharedPreferences on mobile.
      await TokenStore.saveToken(user.userToken);
      await TokenStore.saveUserId(user.id);

      final prefs = await SharedPreferences.getInstance();
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

        // Credentials via TokenStore only (in-memory on web, prefs on mobile).
        if (user.userToken != null) await TokenStore.saveToken(user.userToken!);
        if (user.id != null) await TokenStore.saveUserId(user.id!);

        // Non-sensitive flags can live in SharedPreferences on all platforms.
        final prefs = await SharedPreferences.getInstance();
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

        // Credentials via TokenStore only (in-memory on web, prefs on mobile).
        if (user.userToken != null) await TokenStore.saveToken(user.userToken!);
        if (user.id != null) await TokenStore.saveUserId(user.id!);

        final prefs = await SharedPreferences.getInstance();
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

  /// On-demand recovery for an unverified Firebase email/password account when
  /// the user re-attempts signup. The backend overwrites the unverified
  /// account's password with [password] (Admin SDK) so the client can sign in
  /// and trigger a fresh Firebase verification email.
  ///
  /// Returns the backend status in [message]:
  ///   'RESET'            → unverified; password updated, client should resend
  ///   'NOT_FOUND'        → no Firebase account (client may retry normal signup)
  ///   'ALREADY_VERIFIED' → verified account, route the user to login (409)
  ///   'OTHER_PROVIDER'   → registered via Google etc. (409)
  static Future<ApiResponse<String>> resendVerification({
    required String email,
    required String password,
  }) async {
    try {
      final url = Config.url(Config.resendVerificationUrl);

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.body.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Server is starting up, please try again',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final status = body['data']?['status']?.toString() ?? '';
        return ApiResponse(
          success: true,
          message: status,
          data: status,
        );
      }

      // 409 (already verified / other provider) and any other error.
      return ApiResponse(
        success: false,
        message: body['message'] ?? 'Could not recover this account',
      );
    } catch (e) {
      debugPrint('resendVerification error: $e');
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

        // Credentials via TokenStore only (in-memory on web, prefs on mobile).
        if (user.userToken != null) await TokenStore.saveToken(user.userToken!);
        if (user.id != null) await TokenStore.saveUserId(user.id!);

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

  /// Web session check at startup.
  ///
  /// The web JWT lives only in the HttpOnly cookie, which JavaScript cannot
  /// read — so we can't tell "am I logged in?" from local state. Instead we ask
  /// the backend who we are: `GET /api/users` runs through verifyToken, which
  /// reads the cookie. A 200 means the cookie is still valid (user is logged in
  /// until they explicitly log out, or the 21-day token expires).
  ///
  /// On success the user id is cached in the in-memory [TokenStore] and the
  /// onboarding flag is refreshed. Returns the user id, or null if not logged in.
  static Future<String?> fetchSessionUserId() async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      // Mobile already has the token locally; web relies on the cookie.
      if (!kIsWeb) {
        final token = await TokenStore.getToken();
        if (token == null || token.isEmpty) return null;
        headers['token'] = 'Bearer $token';
      }

      final url = Config.url('/api/users');
      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final body = jsonDecode(response.body);
      final data = body['data'] as Map<String, dynamic>?;
      final id = data?['id']?.toString();
      if (id == null || id.isEmpty) return null;

      await TokenStore.saveUserId(id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', data?['isFirstTimeUser'] != true);

      return id;
    } catch (e) {
      debugPrint('fetchSessionUserId error: $e');
      return null;
    }
  }

  /// Clears the server-side session. On web this tells the backend to expire the
  /// HttpOnly cookie (the only way to remove it, since JS can't touch it). On
  /// mobile it's a harmless no-op — the app clears its own stored token.
  static Future<void> logout() async {
    try {
      await client
          .post(
            Config.url('/api/logout'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('logout request failed: $e');
    }
  }
}
