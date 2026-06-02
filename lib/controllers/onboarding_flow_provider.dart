import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_colors.dart';
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
  String gender = '';
  String phone = '';

  /// Profile photo picked during onboarding.
  XFile? profilePhoto;
  double latitude = 0.0;
  double longitude = 0.0;
  String city = '';
  String state = '';
  String country = '';
  String displayAddress = '';
  String institution = '';
  String degree = '';
  String branch = '';
  String classOf = '';
  String cgpa = '';
  List<String> skills = [];

  /// Current chat step (0-based) the user has reached in [ObChatIntroPage].
  /// Persisted so the conversational onboarding resumes where the user left.
  int chatStep = 0;

  bool get hasLocation => latitude != 0.0 || longitude != 0.0;

  // ── Navigation ─────────────────────────────────────────────────────────────

  static const int _totalPages = 1;

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

  // ── Draft persistence ────────────────────────────────────────────────────
  // The conversational onboarding collects data step-by-step. We snapshot the
  // whole draft to SharedPreferences so the user can leave the app mid-flow
  // and resume from exactly where they left off, with prior answers intact.

  static const List<String> _draftKeys = [
    'ob_step',
    'ob_name',
    'ob_gender',
    'ob_dob',
    'ob_institution',
    'ob_degree',
    'ob_branch',
    'ob_classOf',
    'ob_cgpa',
    'ob_skills',
    'ob_lat',
    'ob_lon',
    'ob_city',
    'ob_state',
    'ob_country',
    'ob_display',
  ];

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ob_step', chatStep);
    await prefs.setString('ob_name', name);
    await prefs.setString('ob_gender', gender);
    await prefs.setString('ob_dob', dob);
    await prefs.setString('ob_institution', institution);
    await prefs.setString('ob_degree', degree);
    await prefs.setString('ob_branch', branch);
    await prefs.setString('ob_classOf', classOf);
    await prefs.setString('ob_cgpa', cgpa);
    await prefs.setStringList('ob_skills', skills);
    await prefs.setDouble('ob_lat', latitude);
    await prefs.setDouble('ob_lon', longitude);
    await prefs.setString('ob_city', city);
    await prefs.setString('ob_state', state);
    await prefs.setString('ob_country', country);
    await prefs.setString('ob_display', displayAddress);
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    chatStep = prefs.getInt('ob_step') ?? chatStep;
    // Keep any constructor-supplied initialName when no draft name was stored.
    name = prefs.getString('ob_name') ?? name;
    gender = prefs.getString('ob_gender') ?? gender;
    dob = prefs.getString('ob_dob') ?? dob;
    institution = prefs.getString('ob_institution') ?? institution;
    degree = prefs.getString('ob_degree') ?? degree;
    branch = prefs.getString('ob_branch') ?? branch;
    classOf = prefs.getString('ob_classOf') ?? classOf;
    cgpa = prefs.getString('ob_cgpa') ?? cgpa;
    skills = prefs.getStringList('ob_skills') ?? skills;
    latitude = prefs.getDouble('ob_lat') ?? latitude;
    longitude = prefs.getDouble('ob_lon') ?? longitude;
    city = prefs.getString('ob_city') ?? city;
    state = prefs.getString('ob_state') ?? state;
    country = prefs.getString('ob_country') ?? country;
    displayAddress = prefs.getString('ob_display') ?? displayAddress;
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _draftKeys) {
      await prefs.remove(key);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    _isLoading = true;
    notifyListeners();

    try {
      final req = ProfileUpdateReq(
        username: name,
        phone: phone,
        dob: dob,
        userType: role,
        gender: gender,
        latitude: latitude,
        longitude: longitude,
        city: city,
        state: state,
        country: country,
        skills: skills,
        education: institution.isEmpty && degree.isEmpty
            ? []
            : [
                EducationItem(
                  college: institution,
                  degree: degree,
                  branch: branch,
                  classOf: classOf,
                  cgpa: cgpa,
                ),
              ],
      );

      final error = await UserHelper.createProfile(req, profilePhoto);

      if (error != null) {
        Get.snackbar(
          'Could Not Save Profile',
          error,
          backgroundColor: kOrange,
          colorText: kLight,
          duration: const Duration(seconds: 6),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      await prefs.remove('onboardingPage');
      await clearDraft();
      Get.offAll(() => const MainScreen(), transition: Transition.fade);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: kOrange,
        colorText: kLight,
      );
      Get.offAll(() => const MainScreen(), transition: Transition.fade);
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
