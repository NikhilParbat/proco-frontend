import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/auth_service.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/auth/signup_model.dart';
import 'package:proco/services/helpers/auth_helper.dart';
import 'package:proco/services/location_service.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/constants/app_constants.dart';

class SignUpNotifier extends ChangeNotifier {
  final SignupModel signupModel = SignupModel();

  // ─── Step navigation ────────────────────────────────────────────────────────

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

  // ─── Location state ──────────────────────────────────────────────────────

  /// The coordinates the user has confirmed on the map.
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _displayAddress = '';
  bool _locationLoading = false;

  double get latitude => _latitude;
  double get longitude => _longitude;
  String get displayAddress => _displayAddress;
  bool get locationLoading => _locationLoading;

  /// Returns true when the user has picked a valid location.
  bool get hasLocation => _latitude != 0.0 || _longitude != 0.0;

  /// Called from the UI after the user taps on the map or confirms a search
  /// result. [displayAddress] is optional and purely cosmetic.
  void setLocation(double lat, double lng, {String displayAddress = ''}) {
    _latitude = lat;
    _longitude = lng;
    _displayAddress = displayAddress;
    signupModel.latitude = lat;
    signupModel.longitude = lng;
    notifyListeners();
  }

  /// Asks [LocationService] for the GPS fix and pushes it into the model.
  /// Returns the [LocationResult] so the UI can animate the map camera,
  /// or null on failure (error is shown via snackbar internally).
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

  /// Geocodes [address] and updates state. Returns the result for the UI to
  /// move the map camera, or null when geocoding fails.
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

  // ─── Regular Signup Submission ───────────────────────────────────────────

  void submitSignup() {
    if (signupModel.username.isEmpty ||
        signupModel.email.isEmpty ||
        signupModel.password.isEmpty ||
        signupModel.college.isEmpty ||
        signupModel.branch.isEmpty ||
        signupModel.gender.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!hasLocation) {
      Get.snackbar(
        'Location Required',
        'Please select your location on the map before continuing.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    AuthHelper.signup(signupModel).then((response) {
      if (response[0]) {
        Get.offAll(
          () => const LoginPage(drawer: true),
          transition: Transition.fade,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Sign Up Failed',
          response[1],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    });
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

      // Step 3: Call backend signup endpoint with location if available
      final response = await AuthHelper.googleSignup(
        idToken: idToken,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        latitude: _latitude != 0.0 ? _latitude : null,
        longitude: _longitude != 0.0 ? _longitude : null,
      );

      // Step 4: Handle response
      Get.closeAllSnackbars(); // Prevent stacking

      if (response.isNotEmpty && response[0] == true) {
        // Save preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedIn', true);
        await prefs.setBool('entrypoint', true);

        _isLoading = false;
        notifyListeners();

        Get.snackbar(
          'Sign Up Success',
          'Welcome, ${firebaseUser.displayName ?? ""}!',
          colorText: kLight,
          backgroundColor: kLightBlue,
          icon: const Icon(Icons.check),
        );

        await Future.delayed(const Duration(seconds: 1));

        // Navigate to main screen
        Get.offAll(() => const MainScreen(), transition: Transition.fade);
      } else {
        _isLoading = false;
        notifyListeners();

        final message = (response.length > 1 && response[1] != null)
            ? response[1].toString()
            : 'Sign up failed';

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
}
