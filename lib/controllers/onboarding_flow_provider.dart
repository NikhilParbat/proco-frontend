import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingFlowProvider extends ChangeNotifier {
  OnboardingFlowProvider({String initialName = '', int initialPage = 0}) {
    name = initialName;
    _currentPage = initialPage;
    pageController = PageController(initialPage: initialPage);
  }

  late final PageController pageController;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Form data ──────────────────────────────────────────────────────────────
  String name = '';

  /// 'Student' or 'Young Professional'.
  /// NOTE: No matching backend field exists yet. This is stored locally only
  /// until the backend adds a `userType` (or equivalent) field.
  String role = '';

  /// Date of birth stored as "YYYY-MM-DD".
  String dob = '';
  String phone = '';

  /// Profile photo picked during onboarding.
  File? profilePhoto;
  double latitude = 0.0;
  double longitude = 0.0;
  String city = '';
  String state = '';
  String country = '';
  String displayAddress = '';
  String institution = '';
  List<String> skills = [];

  bool get hasLocation => latitude != 0.0 || longitude != 0.0;

  // ── Navigation ─────────────────────────────────────────────────────────────

  // Total pages = 8 (indices 0-7). Skills page (7) calls submit() directly.
  static const int _totalPages = 8;

  void nextPage() {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _saveProgress();
      notifyListeners();
    }
  }

  void prevPage() {
    if (_currentPage > 0) {
      _currentPage--;
      pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onboardingPage', _currentPage);
  }

  // ── Location ───────────────────────────────────────────────────────────────

  void setLocation(
    double lat,
    double lng, {
    String displayAddress = '',
    String city = '',
    String state = '',
    String country = '',
  }) {
    latitude = lat;
    longitude = lng;
    this.displayAddress = displayAddress;
    this.city = city;
    this.state = state;
    this.country = country;
    notifyListeners();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    _isLoading = true;
    notifyListeners();

    try {
      final req = ProfileUpdateReq(
        name: name,
        phone: phone,
        dob: dob,
        userType: role,
        college: institution,
        latitude: latitude,
        longitude: longitude,
        city: city,
        state: state,
        country: country,
        skills: skills,
      );

      final error = await UserHelper.createProfile(req, profilePhoto);

      if (error == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboardingComplete', true);
        await prefs.remove('onboardingPage');
        Get.offAll(() => const MainScreen(), transition: Transition.fade);
      } else {
        Get.snackbar(
          'Could Not Save Profile',
          error,
          backgroundColor: kOrange,
          colorText: kLight,
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: kOrange,
        colorText: kLight,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
