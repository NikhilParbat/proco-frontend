import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/services/helpers/auth_helper.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Simple model to hold one device session
class DeviceSession {
  final String device;
  final String platform;
  final String date;

  DeviceSession({
    required this.device,
    required this.platform,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'device': device,
    'platform': platform,
    'date': date,
  };

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    device: json['device'] ?? 'Unknown Device',
    platform: json['platform'] ?? 'Unknown Platform',
    date: json['date'] ?? '',
  );
}

class LoginNotifier extends ChangeNotifier {
  bool _obscureText = true;
  bool get obscureText => _obscureText;
  set obscureText(bool newState) {
    _obscureText = newState;
    notifyListeners();
  }

  bool _firstTime = true;
  bool get firstTime => _firstTime;
  set firstTime(bool newState) {
    _firstTime = newState;
    notifyListeners();
  }

  bool? _entrypoint;
  bool get entrypoint => _entrypoint ?? false;
  set entrypoint(bool newState) {
    if (_entrypoint == newState) return;
    _entrypoint = newState;
    notifyListeners();
  }

  bool? _loggedIn;
  bool get loggedIn => _loggedIn ?? false;
  set loggedIn(bool newState) {
    if (_loggedIn == newState) return;
    _loggedIn = newState;
    notifyListeners();
  }

  List<DeviceSession> _deviceSessions = [];
  List<DeviceSession> get deviceSessions => _deviceSessions;

  void getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    entrypoint = prefs.getBool('entrypoint') ?? false;
    final token = prefs.getString('token');
    loggedIn = token != null;
    await loadDeviceSessions();
  }

  final loginFormKey = GlobalKey<FormState>();
  final profileFormKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = loginFormKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  bool profileValidation() {
    final form = profileFormKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  set isLoading(bool newState) {
    _isLoading = newState;
    notifyListeners();
  }

  Future<void> userLogin(LoginModel model) async {
    _isLoading = true;
    notifyListeners();

    try {
      var response = await AuthHelper.login(model);

      if (response[0]) {
        // ✅ Save this device session on successful login
        await saveDeviceSession();

        Get.snackbar(
          'Login Success',
          'Enjoy your search for a job',
          colorText: kLight,
          backgroundColor: kLightBlue,
          icon: const Icon(Icons.add_alert),
        );

        await Future.delayed(const Duration(seconds: 1));
        _isLoading = false;
        notifyListeners();

        Get.offAll(() => const MainScreen(), transition: Transition.fade);
      } else {
        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          response[1],
          'Please try again',
          colorText: kLight,
          backgroundColor: kOrange,
          icon: const Icon(Icons.add_alert),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      Get.snackbar(
        'Login Failed',
        'An unexpected error occurred',
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.add_alert),
      );
      debugPrint('Login Error: $e');
    }
  }

  // Google Sign-In method
  Future<void> googleSignIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Sign in with Firebase
      final authService = AuthService();
      final userCredential = await authService.signInWithGoogle();

      if (userCredential == null) {
        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          'Login Cancelled',
          'Please try again',
          colorText: kLight,
          backgroundColor: kOrange,
          icon: const Icon(Icons.add_alert),
        );
        return;
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          'Authentication Error',
          'Could not retrieve user information',
          colorText: kLight,
          backgroundColor: kOrange,
          icon: const Icon(Icons.add_alert),
        );
        return;
      }

      // Step 2: Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          'Authentication Error',
          'Could not retrieve authentication token',
          colorText: kLight,
          backgroundColor: kOrange,
          icon: const Icon(Icons.add_alert),
        );
        return;
      }

      // Step 3: Verify with backend via AuthHelper
      final response = await AuthHelper.googleLogin(
        idToken: idToken,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
      );

      // Step 4: Handle response
      Get.closeAllSnackbars(); // 🔥 prevents stacking

      if (response.isNotEmpty && response[0] == true) {
        await saveDeviceSession();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setBool('entrypoint', true);

        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          'Login Success',
          'Welcome back, ${firebaseUser.displayName ?? ""}!',
          colorText: kLight,
          backgroundColor: kLightBlue,
          icon: const Icon(Icons.check),
        );

        await Future.delayed(const Duration(seconds: 1));

        Get.offAll(() => const MainScreen());
      } else {
        _isLoading = false;
        notifyListeners();

        final message = (response.length > 1 && response[1] != null)
            ? response[1].toString()
            : 'Login failed';

        Get.snackbar(
          'Login Failed',
          message,
          colorText: kLight,
          backgroundColor: kOrange,
          icon: const Icon(Icons.error),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint('Google Sign-In Error: $e');
      Get.snackbar(
        'Login Failed',
        'An unexpected error occurred',
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.add_alert),
      );
    }
  }

  Future<void> saveDeviceSession() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown Device';
      String platformName = 'Unknown Platform';

      if (GetPlatform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceName = '${info.manufacturer} ${info.model}';
        platformName = 'Android ${info.version.release}';
      } else if (GetPlatform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceName = info.name;
        platformName = '${info.systemName} ${info.systemVersion}';
      } else if (GetPlatform.isWeb) {
        final info = await deviceInfo.webBrowserInfo;
        deviceName = info.browserName.name;
        platformName = 'Web';
      }

      final date = DateTime.now().toString().substring(0, 10);

      final session = DeviceSession(
        device: deviceName,
        platform: platformName,
        date: date,
      );

      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList('device_sessions') ?? [];

      final alreadyExists = existing.any((e) {
        final decoded = DeviceSession.fromJson(jsonDecode(e));
        return decoded.device == session.device && decoded.date == session.date;
      });

      if (!alreadyExists) {
        existing.add(jsonEncode(session.toJson()));
        await prefs.setStringList('device_sessions', existing);
      }

      await loadDeviceSessions();
    } catch (e) {
      debugPrint('Error saving device session: $e');
    }
  }

  Future<void> loadDeviceSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('device_sessions') ?? [];

      if (stored.isEmpty) {
        _deviceSessions = [];
        notifyListeners();
        return;
      }

      List<DeviceSession> newSessions = stored
          .map((e) => DeviceSession.fromJson(jsonDecode(e)))
          .toList()
          .reversed
          .toList();

      if (_deviceSessions.length == newSessions.length) return;

      _deviceSessions = newSessions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading device sessions: $e');
    }
  }

  Future<void> removeDeviceSession(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('device_sessions') ?? [];

      final originalIndex = stored.length - 1 - index;
      if (originalIndex >= 0 && originalIndex < stored.length) {
        stored.removeAt(originalIndex);
        await prefs.setStringList('device_sessions', stored);
        await loadDeviceSessions();
      }
    } catch (e) {
      debugPrint('Error removing device session: $e');
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);
    await prefs.setBool('entrypoint', false);
    await prefs.remove('token');
    await prefs.remove('profile');
    await prefs.remove('userId');
    await prefs.remove('device_sessions');

    // ✅ Also sign out from Firebase
    await AuthService().signOut();

    _deviceSessions = [];
    _loggedIn = false;
    _entrypoint = false;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    Get.offAll(() => const LoginPage(drawer: true));
  }
}

// ✅ AuthService with Singleton pattern - UPDATED for google_sign_in v7.x
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();

      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential using the updated field names
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
