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
import 'package:proco/views/common/lagoon_snackbar.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      LagoonSnackbar.showError(title: 'Location Error', message: e.toString());
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
        LagoonSnackbar.showError(
          title: 'Address Not Found',
          message:
              'Could not find coordinates for "$address". Try a different query.',
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
      LagoonSnackbar.showError(title: 'Geocoding Error', message: e.toString());
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
        LagoonSnackbar.showError(
          title: 'Sign Up Failed',
          message: 'Could not create account. Please try again.',
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
      LagoonSnackbar.showError(
        title: 'Sign Up Failed',
        message: _firebaseAuthMessage(e.code),
      );
    } catch (e) {
      isLoading = false;
      LagoonSnackbar.showError(title: 'Sign Up Failed', message: e.toString());
    }
  }

  /// Handles re-signup when the email already exists in Firebase.
  ///
  /// The user signed up before but never verified, so Firebase still holds an
  /// unverified account and refuses a fresh `createUser` ("email-already-in-use")
  /// while login is impossible (DB users are verified-only). We heal this:
  ///
  ///  1. Ask the backend to recover the account. For an UNVERIFIED account it
  ///     overwrites the stored password with the freshly-typed one (Admin SDK),
  ///     so a different password on re-signup simply replaces the old one.
  ///  2. Sign in with that password (now guaranteed to match) and trigger a new
  ///     Firebase verification email via `sendEmailVerification()`.
  ///
  /// A VERIFIED account is never touched by the backend — it returns 409 and we
  /// route the user to login (their existing flow already handles that case).
  Future<void> _recoverExistingFirebaseAccount() async {
    isLoading = true;
    try {
      final recovery = await AuthHelper.resendVerification(
        email: signupModel.email,
        password: signupModel.password,
      );

      if (!recovery.success) {
        // 409 ALREADY_VERIFIED → "please log in", or OTHER_PROVIDER → use Google.
        isLoading = false;
        LagoonSnackbar.showError(
          title: 'Account Already Exists',
          message: recovery.message,
        );
        return;
      }

      if (recovery.data == 'NOT_FOUND') {
        // Race: the Firebase account vanished between create and recover.
        // Retry a clean signup now that the email is free.
        isLoading = false;
        await submitEmailSignup();
        return;
      }

      // recovery.data == 'RESET': the unverified account now uses the typed
      // password. Sign in and re-send the Firebase verification email.
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: signupModel.email,
        password: signupModel.password,
      );

      final user = credential.user;
      if (user == null) {
        isLoading = false;
        LagoonSnackbar.showError(
          title: 'Error',
          message: 'Could not access account. Please try again.',
        );
        return;
      }

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
      LagoonSnackbar.show(
        title: 'Verify Your Email',
        message:
            'You signed up earlier but didn\'t verify. We\'ve sent a new '
            'verification link — please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      LagoonSnackbar.showError(
        title: 'Sign Up Failed',
        message: _firebaseAuthMessage(e.code),
      );
    } catch (e) {
      isLoading = false;
      LagoonSnackbar.showError(title: 'Error', message: e.toString());
    }
  }

  /// Resend verification email (user taps "Resend" on step 3).
  Future<void> resendVerificationEmail() async {
    try {
      // Fall back to currentUser when _firebaseUser is null (app was restarted)
      final user = _firebaseUser ?? FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      LagoonSnackbar.show(
        title: 'Email Sent',
        message: 'Verification email resent. Check your inbox.',
      );
    } catch (_) {
      LagoonSnackbar.showError(
        title: 'Error',
        message: 'Could not resend email. Please try again.',
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
        LagoonSnackbar.showError(
          title: 'Session Expired',
          message: 'Your session has expired. Please sign up again.',
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
        LagoonSnackbar.showError(
          title: 'Not Verified Yet',
          message:
              'Please open the link in the email first, then tap this button.',
        );
      }
    } catch (e) {
      debugPrint('checkVerifiedAndProceed error: $e');
      LagoonSnackbar.showError(
        title: 'Error',
        message: 'Could not check verification. Please try again.',
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
        LagoonSnackbar.show(
          title: 'Email Verified!',
          message:
              'Please re-enter your details to finish creating your account.',
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
        LagoonSnackbar.showError(
          title: 'Sign Up Failed',
          message: signupResponse.message,
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

        LagoonSnackbar.show(
          title: 'Email Verified!',
          message: 'Welcome! Let\'s set up your profile.',
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
        LagoonSnackbar.showError(
          title: 'Sign Up Failed',
          message: loginResponse.message,
        );
      }
    } catch (e) {
      isLoading = false;
      LagoonSnackbar.showError(title: 'Error', message: e.toString());
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

        LagoonSnackbar.showError(
          title: 'Sign Up Cancelled',
          message: 'Please try again',
        );
        return;
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _isLoading = false;
        notifyListeners();

        LagoonSnackbar.showError(
          title: 'Authentication Error',
          message: 'Could not retrieve user information',
        );
        return;
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();

        LagoonSnackbar.showError(
          title: 'Authentication Error',
          message: 'Could not retrieve authentication token',
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

      if (response.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setBool('entrypoint', true);

        await _saveDeviceSession();

        _isLoading = false;
        notifyListeners();

        final user = response.data!;

        if (user.isFirstTimeUser == true) {
          LagoonSnackbar.show(
            title: 'Welcome!',
            message: 'Let\'s set up your profile.',
          );

          await Future.delayed(const Duration(seconds: 1));

          Get.offAll(
            () => OnboardingFlow(initialName: firebaseUser.displayName ?? ''),
            transition: Transition.fade,
          );
        } else {
          LagoonSnackbar.show(
            title: 'Welcome Back!',
            message: 'Signed in with Google.',
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

        if (loginResponse.success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('loggedIn', true);
          await prefs.setBool('entrypoint', true);

          await _saveDeviceSession();

          _isLoading = false;
          notifyListeners();

          final user = loginResponse.data!;

          if (user.isFirstTimeUser == true) {
            LagoonSnackbar.show(
              title: 'Welcome!',
              message: 'Let\'s finish setting up your profile.',
            );

            await Future.delayed(const Duration(seconds: 1));

            Get.offAll(
              () => OnboardingFlow(initialName: firebaseUser.displayName ?? ''),
              transition: Transition.fade,
            );
          } else {
            LagoonSnackbar.show(
              title: 'Welcome Back!',
              message: 'You already have an account. Logging you in...',
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

        LagoonSnackbar.showError(title: 'Sign Up Failed', message: message);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint('Google Sign-Up Error: $e');
      LagoonSnackbar.showError(
        title: 'Sign Up Failed',
        message: 'An unexpected error occurred: ${e.toString()}',
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
