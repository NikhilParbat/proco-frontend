import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditState extends ChangeNotifier {
  // Data Fields
  String username = '',
      email = '',
      phone = '',
      gender = '',
      city = '',
      state = '',
      country = '';
  String college = '',
      branch = '',
      profileImageUrl = '',
      dob = '',
      userType = '';
  String linkedInUrl = '', gitHubUrl = '', twitterUrl = '', portfolioUrl = '';
  double latitude = 0.0, longitude = 0.0;
  List<String> skills = [], interests = [], hobbies = [];

  // Visibility Flags
  bool showEmail = true,
      showPhone = true,
      showGender = true,
      showDob = true,
      showCollege = true,
      showSkills = true,
      showLinkedIn = true,
      showGitHub = true,
      showTwitter = true,
      showPortfolio = true;

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

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await UserHelper.getProfile();
      if (res.success && res.data != null) {
        final d = res.data!;
        username = d.username;
        email = d.email;
        phone = d.phone ?? '';
        gender = d.gender ?? '';
        city = d.city ?? '';
        state = d.state ?? '';
        country = d.country ?? '';
        college = d.college ?? '';
        branch = d.branch ?? '';
        profileImageUrl = d.profile ?? '';
        dob = d.dob ?? '';
        userType = d.userType ?? '';
        linkedInUrl = d.linkedInUrl ?? '';
        gitHubUrl = d.gitHubUrl ?? '';
        twitterUrl = d.twitterUrl ?? '';
        portfolioUrl = d.portfolioUrl ?? '';
        skills = List.from(d.skills);
        interests = List.from(d.interests ?? []);
        hobbies = List.from(d.hobbies ?? []);
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> saveProfile(File? image) async {
    isSaving = true;
    notifyListeners();
    final req = ProfileUpdateReq(
      username: username,
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
      interests: interests,
      hobbies: hobbies,
      latitude: latitude,
      longitude: longitude,
      linkedInUrl: linkedInUrl,
      gitHubUrl: gitHubUrl,
      twitterUrl: twitterUrl,
      portfolioUrl: portfolioUrl,
    );
    final res = await UserHelper.updateProfile(req, image);
    isSaving = false;
    if (res.success) await loadProfile();
    notifyListeners();
    return res.success;
  }

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
    notifyListeners();
  }
}
