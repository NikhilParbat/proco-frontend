import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/auth_service.dart';
import 'package:proco/models/request/auth/google_auth_model.dart';
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/models/request/auth/signup_model.dart';
import 'package:proco/services/helpers/auth_helper.dart';
import 'package:proco/services/helpers/device_helper.dart';
import 'package:proco/services/location_service.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class SignUpNotifier extends ChangeNotifier {
  SignupRequestModel signupModel = SignupRequestModel(
    username: '',
    email: '',
    password: '',
  );

  // ─── Step navigation ────────────────────────────────────────────────────────
  // Steps: 0=choice, 1=email, 2=password, 3=verify email

  int _activeIndex = 0;
  int get activeIndex => _activeIndex;

  set activeIndex(int index) {
    if (_activeIndex != index) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void changeStep(int index) => activeIndex = index;

  // ─── Password visibility ─────────────────────────────────────────────────

  bool _obscureText = true;
  bool get obscureText => _obscureText;

  set obscureText(bool newState) {
    if (_obscureText != newState) {
      _obscureText = newState;
      notifyListeners();
    }
  }

  // ─── Loading state ────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  set isLoading(bool newState) {
    if (_isLoading != newState) {
      _isLoading = newState;
      notifyListeners();
    }
  }

  // ─── Email verification state ─────────────────────────────────────────────

  User? _firebaseUser;

  bool _checkingVerification = false;
  bool get checkingVerification => _checkingVerification;

  // ─── Location state ──────────────────────────────────────────────────────

  double _latitude = 0.0;
  double _longitude = 0.0;
  String _displayAddress = '';
  bool _locationLoading = false;

  double get latitude => _latitude;
  double get longitude => _longitude;
  String get displayAddress => _displayAddress;
  bool get locationLoading => _locationLoading;

  bool get hasLocation => _latitude != 0.0 || _longitude != 0.0;

  void setLocation(double lat, double lng, {String displayAddress = ''}) {
    _latitude = lat;
    _longitude = lng;
    _displayAddress = displayAddress;
    signupModel.latitude = lat;
    signupModel.longitude = lng;
    notifyListeners();
  }

  Future<LocationResult?> fetchCurrentLocation() async {
    _locationLoading = true;
    notifyListeners();

    try {
      final result = await LocationService.getCurrentLocation();
      setLocation(
        result.latitude,
        result.longitude,
        displayAddress: result.displayAddress ?? '',
      );
      return result;
    } catch (e) {
      Get.snackbar(
        'Location Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _locationLoading = false;
      notifyListeners();
    }
  }

  Future<LocationResult?> geocodeAndSet(String address) async {
    _locationLoading = true;
    notifyListeners();

    try {
      final result = await LocationService.geocodeAddress(address);
      if (result == null) {
        Get.snackbar(
          'Address Not Found',
          'Could not find coordinates for "$address". Try a different query.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return null;
      }
      setLocation(
        result.latitude,
        result.longitude,
        displayAddress: result.displayAddress ?? address,
      );
      return result;
    } catch (e) {
      Get.snackbar(
        'Geocoding Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _locationLoading = false;
      notifyListeners();
    }
  }

  // ─── Validation ──────────────────────────────────────────────────────────

  bool passwordValidator(String password) {
    if (password.isEmpty) return false;
    const pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    return RegExp(pattern).hasMatch(password);
  }

  // ─── Email + Password Firebase Sign-Up ───────────────────────────────────

  /// Step 2 → Step 3: Creates Firebase user, sends verification email.
  Future<void> submitEmailSignup() async {
    isLoading = true;

    try {
      final authService = AuthService();
      final credential = await authService.createUserWithEmail(
        signupModel.email,
        signupModel.password,
      );

      _firebaseUser = credential.user;

      if (_firebaseUser == null) {
        isLoading = false;
        Get.snackbar(
          'Sign Up Failed',
          'Could not create account. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _firebaseUser!.sendEmailVerification();

      // Persist pending verification so the app can restore step 3 if killed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingVerificationEmail', _firebaseUser!.email!);
      await prefs.setString(
        'pendingVerificationUsername',
        signupModel.username,
      );

      isLoading = false;
      changeStep(
        3,
      ); // verification pending screen — user taps button to confirm
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      if (e.code == 'email-already-in-use') {
        // Firebase account exists but the DB record may be missing (e.g. the
        // app crashed after verification before /api/register completed).
        // Try to recover by signing in and completing the flow.
        await _recoverExistingFirebaseAccount();
        return;
      }
      Get.snackbar(
        'Sign Up Failed',
        _firebaseAuthMessage(e.code),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading = false;
      Get.snackbar(
        'Sign Up Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Handles the split-brain case: Firebase account exists but the DB user
  /// may be missing. Signs into Firebase, then checks verification state.
  Future<void> _recoverExistingFirebaseAccount() async {
    isLoading = true;
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: signupModel.email,
        password: signupModel.password,
      );

      final user = credential.user;
      if (user == null) {
        isLoading = false;
        Get.snackbar(
          'Error',
          'Could not access account.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await user.reload();
      await user.getIdToken(true);
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed?.emailVerified == true) {
        // Verified but DB record missing — create it now.
        await _completeEmailSignup(refreshed!);
      } else {
        // Not yet verified — restore step 3 and resend the email.
        _firebaseUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingVerificationEmail', user.email!);
        await prefs.setString(
          'pendingVerificationUsername',
          signupModel.username,
        );
        await user.sendEmailVerification();
        isLoading = false;
        changeStep(3);
        Get.snackbar(
          'Verify Your Email',
          'A new verification link has been sent. Please check your inbox.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        Get.snackbar(
          'Account Already Exists',
          'An account with this email exists. Please log in instead.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Sign Up Failed',
          _firebaseAuthMessage(e.code),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading = false;
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Resend verification email (user taps "Resend" on step 3).
  Future<void> resendVerificationEmail() async {
    try {
      // Fall back to currentUser when _firebaseUser is null (app was restarted)
      final user = _firebaseUser ?? FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      Get.snackbar(
        'Email Sent',
        'Verification email resent. Check your inbox.',
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not resend email. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ─── Verification check (on-demand) ─────────────────────────────────────

  /// Called when the user taps "I've verified my email".
  /// Always reloads via FirebaseAuth.instance.currentUser to avoid stale references.
  Future<void> checkVerifiedAndProceed() async {
    if (_checkingVerification) return;
    _checkingVerification = true;
    notifyListeners();

    try {
      // Use FirebaseAuth.instance.currentUser directly — never rely on the
      // stored _firebaseUser reference which may be stale if the app restarted.
      final current = FirebaseAuth.instance.currentUser;

      if (current == null) {
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please sign up again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        changeStep(0);
        return;
      }

      // Step 1: reload() fetches latest user state from server.
      await current.reload();

      // Step 2: getIdToken(true) forces a full token refresh, busting all
      // local caches. This is the most reliable way to get updated emailVerified.
      await current.getIdToken(true);

      // Step 3: get a completely fresh reference after both refreshes.
      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed?.emailVerified == true) {
        await _completeEmailSignup(refreshed!);
      } else {
        Get.snackbar(
          'Not Verified Yet',
          'Please open the link in the email first, then tap this button.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('checkVerifiedAndProceed error: $e');
      Get.snackbar(
        'Error',
        'Could not check verification. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _checkingVerification = false;
      notifyListeners();
    }
  }

  /// Called once email verification is confirmed.
  /// Creates the DB user via /api/register (password stored), then logs in.
  Future<void> _completeEmailSignup(User user) async {
    isLoading = true;

    try {
      // Edge-case: app was killed before verification — password is gone.
      if (signupModel.password.isEmpty) {
        isLoading = false;
        Get.snackbar(
          'Email Verified!',
          'Please re-enter your details to finish creating your account.',
          backgroundColor: kLightBlue,
          colorText: Colors.white,
        );
        changeStep(0);
        return;
      }

      // Link the Firebase UID so the account can be found by UID later.
      signupModel.firebaseUid = user.uid;

      // Step 1 — create DB user (POST /api/register).
      final signupResponse = await AuthHelper.signup(signupModel);

      final registrationOk =
          signupResponse.success ||
          signupResponse.message.toLowerCase().contains('exist') ||
          signupResponse.message.toLowerCase().contains('already');

      if (!registrationOk) {
        isLoading = false;
        Get.snackbar(
          'Sign Up Failed',
          signupResponse.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Step 2 — log in to get JWT (POST /api/login).
      final loginResponse = await AuthHelper.login(
        LoginRequestModel(
          email: signupModel.email,
          password: signupModel.password,
        ),
      );

      if (loginResponse.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('entrypoint', true);
        await prefs.remove('pendingVerificationEmail');
        await prefs.remove('pendingVerificationUsername');

        await _saveDeviceSession();

        isLoading = false;

        Get.snackbar(
          'Email Verified!',
          'Welcome! Let\'s set up your profile.',
          backgroundColor: kLightBlue,
          colorText: Colors.white,
        );

        await Future.delayed(const Duration(milliseconds: 800));

        final loginUser = loginResponse.data!;
        if (loginUser.isFirstTimeUser) {
          Get.offAll(
            () => OnboardingFlow(initialName: signupModel.username),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 600),
          );
        } else {
          Get.offAll(() => const MainScreen(), transition: Transition.fade);
        }
      } else {
        isLoading = false;
        Get.snackbar(
          'Sign Up Failed',
          loginResponse.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading = false;
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use 8+ chars with mixed case, digit & symbol.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  // ✅ ─── Google Sign-Up ───────────────────────────────────────────────────

  Future<void> googleSignUp() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final userCredential = await authService.signInWithGoogle();

      if (userCredential == null) {
        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          'Sign Up Cancelled',
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
        latitude: _latitude != 0.0 ? _latitude : null,
        longitude: _longitude != 0.0 ? _longitude : null,
      );

      final response = await AuthHelper.googleSignup(model);

      Get.closeAllSnackbars();

      if (response.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setBool('entrypoint', true);

        await _saveDeviceSession();

        _isLoading = false;
        notifyListeners();

        final user = response.data!;

        if (user.isFirstTimeUser == true) {
          Get.snackbar(
            'Welcome!',
            'Let\'s set up your profile.',
            colorText: kLight,
            backgroundColor: kLightBlue,
            icon: const Icon(Icons.check),
          );

          await Future.delayed(const Duration(seconds: 1));

          Get.offAll(
            () => OnboardingFlow(initialName: firebaseUser.displayName ?? ''),
            transition: Transition.fade,
          );
        } else {
          Get.snackbar(
            'Welcome Back!',
            'Signed in with Google.',
            colorText: kLight,
            backgroundColor: kLightBlue,
            icon: const Icon(Icons.check),
          );

          await Future.delayed(const Duration(seconds: 1));

          Get.offAll(() => const MainScreen(), transition: Transition.fade);
        }
      } else {
        // ── Fallback: same Google account already registered → auto-login ─
        // Triggered when the backend returns 409 (googleSignup endpoint).
        // Firebase already authenticated them, so we use the same idToken
        // to log them straight in.

        final loginResponse = await AuthHelper.googleLogin(model);

        Get.closeAllSnackbars();

        if (loginResponse.success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('loggedIn', true);
          await prefs.setBool('entrypoint', true);

          await _saveDeviceSession();

          _isLoading = false;
          notifyListeners();

          final user = loginResponse.data!;

          if (user.isFirstTimeUser == true) {
            Get.snackbar(
              'Welcome!',
              'Let\'s finish setting up your profile.',
              colorText: kLight,
              backgroundColor: kLightBlue,
              icon: const Icon(Icons.check),
            );

            await Future.delayed(const Duration(seconds: 1));

            Get.offAll(
              () => OnboardingFlow(initialName: firebaseUser.displayName ?? ''),
              transition: Transition.fade,
            );
          } else {
            Get.snackbar(
              'Welcome Back!',
              'You already have an account. Logging you in...',
              colorText: kLight,
              backgroundColor: kLightBlue,
              icon: const Icon(Icons.check),
            );

            await Future.delayed(const Duration(seconds: 1));

            Get.offAll(() => const MainScreen(), transition: Transition.fade);
          }

          return;
        }
        // Both signup and login failed — show the original signup error.
        _isLoading = false;
        notifyListeners();

        final message = response.message;

        Get.snackbar(
          'Sign Up Failed',
          message,
          colorText: kLight,
          backgroundColor: kOrange,
          icon: const Icon(Icons.error),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint('Google Sign-Up Error: $e');
      Get.snackbar(
        'Sign Up Failed',
        'An unexpected error occurred: ${e.toString()}',
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.add_alert),
      );
    }
  }

  // ─── Device session registration after signup ─────────────────────────────
  Future<void> _saveDeviceSession() async {
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
      final sessionId = prefs.getString('deviceSessionId') ?? const Uuid().v4();
      await prefs.setString('deviceSessionId', sessionId);

      await DeviceHelper.registerDeviceSession(
        sessionId: sessionId,
        device: deviceName,
        platform: platformName,
        date: DateTime.now().toString().substring(0, 10),
      );
    } catch (e) {
      debugPrint('SignUpNotifier: error saving device session: $e');
    }
  }
}
