import 'dart:io';

import 'package:flutter/material.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditState extends ChangeNotifier {
  // ── Backend fields ───────────────────────────────────────────────────────────
  String username = '';
  String email = '';
  String phone = '';
  String gender = '';
  String city = '';
  String state = '';
  String country = '';
  String college = '';
  String branch = '';
  List<String> skills = [];
  String profileImageUrl = '';

  // ── NEW: Location Coordinates ───────────────────────────────────────────────
  double latitude = 0.0;
  double longitude = 0.0;

  String userType = ''; // 'Student' | 'Young Professional'
  String dob = ''; // Date of birth, stored as "YYYY-MM-DD"
  String linkedInUrl = '';
  String gitHubUrl = '';
  String twitterUrl = '';
  String portfolioUrl = '';

  // ── Per-field visibility flags ───────────────────────────────────────────────
  bool showEmail = true;
  bool showPhone = true;
  bool showGender = true;
  bool showDob = true;
  bool showCollege = true;
  bool showSkills = true;
  bool showLinkedIn = true;
  bool showGitHub = true;
  bool showTwitter = true;
  bool showPortfolio = true;

  // ── Async state ──────────────────────────────────────────────────────────────
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  ProfileEditState() {
    _init();
  }

  Future<void> _init() async {
    await _loadVisibility();
    await loadProfile();
  }

  // ── Load backend profile + local extras ──────────────────────────────────────
  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await UserHelper.getProfile();

      if (!response.success) {
        error = response.message;
        return;
      }

      final data = response.data;

      if (data != null) {
        username = data.username;
        email = data.email;
        phone = data.phone ?? '';
        gender = data.gender ?? '';
        city = data.city ?? '';
        state = data.state ?? '';
        country = data.country ?? '';
        college = data.college ?? '';
        branch = data.branch ?? '';
        profileImageUrl = data.profile ?? '';
        latitude = data.latitude ?? 0.0;
        longitude = data.longitude ?? 0.0;

        // ⚠️ Backend does NOT send these (yet)
        dob = '';
        userType = '';
        linkedInUrl = '';
        gitHubUrl = '';
        twitterUrl = '';
        portfolioUrl = '';

        // ⚠️ Skills not in response
        skills = [];
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Save to backend ───────────────────────────────────────────────────────────
  Future<bool> saveProfile(File? image) async {
    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final req = ProfileUpdateReq(
        username: username, // ✅ IMPORTANT (you were missing this)
        city: city,
        state: state,
        country: country,
        phone: phone,
        skills: skills,
        college: college,
        branch: branch,
        gender: gender.isEmpty ? null : gender,
        dob: dob,
        userType: userType,
        linkedInUrl: linkedInUrl,
        gitHubUrl: gitHubUrl,
        twitterUrl: twitterUrl,
        portfolioUrl: portfolioUrl,
        latitude: latitude,
        longitude: longitude,
      );

      final response = await UserHelper.updateProfile(req, image);

      isSaving = false;

      if (!response.success) {
        error = response.message;
        notifyListeners();
        return false;
      }

      final user = response.data;
      if (user != null) {
        username = user.username;
        email = user.email;
        phone = user.phone ?? '';
        city = user.city ?? '';
        state = user.state ?? '';
        country = user.country ?? '';
        college = user.college ?? '';
        branch = user.branch ?? '';
        gender = user.gender ?? '';
        latitude = user.latitude ?? 0.0;
        longitude = user.longitude ?? 0.0;
        profileImageUrl = user.profile ?? '';
      }

      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Setters ──────────────────────────────────────────────────────────────────
  void setCoordinates(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  // ── Per-field visibility ──────────────────────────────────────────────────────
  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    showEmail = prefs.getBool('vis_email') ?? true;
    showPhone = prefs.getBool('vis_phone') ?? true;
    showGender = prefs.getBool('vis_gender') ?? true;
    showDob = prefs.getBool('vis_dob') ?? true;
    showCollege = prefs.getBool('vis_college') ?? true;
    showSkills = prefs.getBool('vis_skills') ?? true;
    showLinkedIn = prefs.getBool('vis_linkedin') ?? true;
    showGitHub = prefs.getBool('vis_github') ?? true;
    showTwitter = prefs.getBool('vis_twitter') ?? true;
    showPortfolio = prefs.getBool('vis_portfolio') ?? true;
  }

  Future<void> toggleVisibility(String key) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'email':
        showEmail = !showEmail;
        await prefs.setBool('vis_email', showEmail);
        break;
      case 'phone':
        showPhone = !showPhone;
        await prefs.setBool('vis_phone', showPhone);
        break;
      case 'gender':
        showGender = !showGender;
        await prefs.setBool('vis_gender', showGender);
        break;
      case 'dob':
        showDob = !showDob;
        await prefs.setBool('vis_dob', showDob);
        break;
      case 'college':
        showCollege = !showCollege;
        await prefs.setBool('vis_college', showCollege);
        break;
      case 'skills':
        showSkills = !showSkills;
        await prefs.setBool('vis_skills', showSkills);
        break;
      case 'linkedin':
        showLinkedIn = !showLinkedIn;
        await prefs.setBool('vis_linkedin', showLinkedIn);
        break;
      case 'github':
        showGitHub = !showGitHub;
        await prefs.setBool('vis_github', showGitHub);
        break;
      case 'twitter':
        showTwitter = !showTwitter;
        await prefs.setBool('vis_twitter', showTwitter);
        break;
      case 'portfolio':
        showPortfolio = !showPortfolio;
        await prefs.setBool('vis_portfolio', showPortfolio);
        break;
    }
    notifyListeners();
  }

  // ── Setters ──────────────────────────────────────────────────────────────────
  void setField(String key, String value) {
    switch (key) {
      case 'phone':
        phone = value;
        break;
      case 'gender':
        gender = value;
        break;
      case 'dob':
        dob = value;
        break;
      case 'city':
        city = value;
        break;
      case 'state':
        state = value;
        break;
      case 'country':
        country = value;
        break;
      case 'college':
        college = value;
        break;
      case 'branch':
        branch = value;
        break;
      case 'linkedin':
        linkedInUrl = value;
        break;
      case 'github':
        gitHubUrl = value;
        break;
      case 'twitter':
        twitterUrl = value;
        break;
      case 'portfolio':
        portfolioUrl = value;
        break;
    }
    notifyListeners();
  }

  void addSkill(String skill) {
    if (skill.isNotEmpty && !skills.contains(skill)) {
      skills = [...skills, skill];
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    skills = skills.where((s) => s != skill).toList();
    notifyListeners();
  }
}
