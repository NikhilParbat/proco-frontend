import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/auth_service.dart';
import 'package:proco/models/request/auth/google_auth_model.dart';
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/services/helpers/auth_helper.dart';
import 'package:proco/services/helpers/device_helper.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Model for one device session (matches backend schema)
class DeviceSession {
  final String sessionId;
  final String device;
  final String platform;
  final String date;

  DeviceSession({
    required this.sessionId,
    required this.device,
    required this.platform,
    required this.date,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    sessionId: json['sessionId'] ?? '',
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

  Future<void> userLogin(LoginRequestModel model) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await AuthHelper.login(model);

      if (response.success && response.data != null) {
        final user = response.data!;

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

        // ✅ Use typed value instead of guessing from array
        if (user.isFirstTimeUser == true) {
          Get.offAll(() => const OnboardingFlow(), transition: Transition.fade);
        } else {
          Get.offAll(() => const MainScreen(), transition: Transition.fade);
        }
      } else {
        _isLoading = false;
        notifyListeners();

        final msg = response.message;

        final isNotFound =
            msg.toLowerCase().contains('sign up') ||
            msg.toLowerCase().contains('no account');

        Get.snackbar(
          isNotFound ? 'Account Not Found' : 'Login Failed',
          msg,
          colorText: kLight,
          backgroundColor: isNotFound ? kLightBlue : kOrange,
          icon: Icon(isNotFound ? Icons.person_add_outlined : Icons.add_alert),
          duration: const Duration(seconds: 4),
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

      final model = GoogleAuthModel(
        idToken: idToken,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
      );

      final response = await AuthHelper.googleLogin(model);

      Get.closeAllSnackbars();

      if (response.success) {
        await saveDeviceSession();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setBool('entrypoint', true);

        _isLoading = false;
        notifyListeners();

        final user = response.data!; // ✅ FIX
        final isFirstTimeUser = user.isFirstTimeUser == true; // ✅ FIX

        Get.snackbar(
          'Login Success',
          'Welcome back, ${firebaseUser.displayName ?? ""}!',
          colorText: kLight,
          backgroundColor: kLightBlue,
          icon: const Icon(Icons.check),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (isFirstTimeUser) {
          Get.offAll(
            () => OnboardingFlow(initialName: firebaseUser.displayName ?? ''),
            transition: Transition.fade,
          );
        } else {
          Get.offAll(() => const MainScreen());
        }
      } else {
        _isLoading = false;
        notifyListeners();

        final message = response.message; // ✅ FIX

        final isNotFound =
            message.toLowerCase().contains('sign up') ||
            message.toLowerCase().contains('no account');

        Get.snackbar(
          isNotFound ? 'Account Not Found' : 'Login Failed',
          message,
          colorText: kLight,
          backgroundColor: isNotFound ? kLightBlue : kOrange,
          icon: Icon(isNotFound ? Icons.person_add_outlined : Icons.error),
          duration: const Duration(seconds: 4),
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
  // ─── Device Session Management (backend-backed) ───────────────────────────

  /// Collects device info, generates a unique sessionId, registers it with the
  /// backend, and stores the sessionId in SharedPreferences for later reference.
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

      final prefs = await SharedPreferences.getInstance();
      // Reuse the existing sessionId for this installation so we don't create
      // duplicate entries on every login.
      String sessionId =
          prefs.getString('deviceSessionId') ?? const Uuid().v4();
      await prefs.setString('deviceSessionId', sessionId);

      final date = DateTime.now().toString().substring(0, 10);

      await DeviceHelper.registerDeviceSession(
        sessionId: sessionId,
        device: deviceName,
        platform: platformName,
        date: date,
      );

      await loadDeviceSessions();
    } catch (e) {
      debugPrint('Error saving device session: $e');
    }
  }

  /// Fetches the list of sessions from the backend.
  Future<void> loadDeviceSessions() async {
    try {
      final raw = await DeviceHelper.fetchDeviceSessions();
      final sessions = raw
          .map((e) => DeviceSession.fromJson(e))
          .toList()
          .reversed
          .toList();
      _deviceSessions = sessions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading device sessions: $e');
    }
  }

  /// Removes a single device session by index.
  /// If the removed session is the current device's session, the user is signed
  /// out; otherwise the entry is just removed from the backend list.
  Future<void> removeDeviceSession(int index) async {
    try {
      if (index < 0 || index >= _deviceSessions.length) return;

      final session = _deviceSessions[index];

      await DeviceHelper.removeDeviceSession(session.sessionId);

      final prefs = await SharedPreferences.getInstance();
      final currentSessionId = prefs.getString('deviceSessionId') ?? '';

      if (session.sessionId == currentSessionId) {
        // Signing out of the current device — full logout.
        logout();
      } else {
        await loadDeviceSessions();
      }
    } catch (e) {
      debugPrint('Error removing device session: $e');
    }
  }

  void logout() async {
    // Best-effort: clear all sessions on the backend before wiping local state.
    await DeviceHelper.removeAllDeviceSessions();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);
    await prefs.setBool('entrypoint', false);
    await prefs.remove('token');
    await prefs.remove('profile');
    await prefs.remove('userId');
    await prefs.remove('deviceSessionId');
    await prefs.remove('onboardingComplete');
    await prefs.remove('onboardingPage');

    await AuthService().signOut();

    _deviceSessions = [];
    _loggedIn = false;
    _entrypoint = false;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    Get.offAll(() => const LoginPage(drawer: true));
  }
}
