import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/models/response/auth/profile_model.dart';

class ProfileEditState extends ChangeNotifier {
  // Data Fields
  String username = '', bio = '', email = '', phone = '', gender = '', city = '', state = '', country = '';
  String college = '', branch = '', profileImageUrl = '', dob = '', userType = '';
  String linkedInUrl = '', gitHubUrl = '', twitterUrl = '', portfolioUrl = '';
  double latitude = 0.0, longitude = 0.0;
  List<String> skills = [], interests = [], hobbies = [];
  List<ExperienceItem> experiences = [];
  List<ProjectItem> projects = [];
  List<AchievementItem> achievements = [];
  int queriesCreated = 0;

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

  // Visibility Flags and Status
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  final String? _viewUserId;
  bool get isReadOnly => _viewUserId != null;

  ProfileEditState({String? viewUserId}) : _viewUserId = viewUserId {
    _init();
  }

  // ── List Management Helpers ──────────────────────────────────────────────
  // These are crucial for the UI to add/remove items dynamically

  void addSkill(String skill) {
    if (skill.isNotEmpty && !skills.contains(skill)) {
      skills.add(skill);
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    skills.remove(skill);
    notifyListeners();
  }

  void addInterest(String interest) {
    if (interest.isNotEmpty && !interests.contains(interest)) {
      interests.add(interest);
      notifyListeners();
    }
  }

  void removeInterest(String interest) {
    interests.remove(interest);
    notifyListeners();
  }

  void addHobbies(String hobby) {
    if (hobby.isNotEmpty && !hobbies.contains(hobby)) {
      hobbies.add(hobby);
      notifyListeners();
    }
  }

  void removeHobby(String hobby) {
    hobbies.remove(hobby);
    notifyListeners();
  }

  void addExperience(ExperienceItem item) {
    experiences.add(item);
    notifyListeners();
  }

  void removeExperience(int index) {
    experiences.removeAt(index);
    notifyListeners();
  }

  void addProject(ProjectItem item) {
    projects.add(item);
    notifyListeners();
  }

  void removeProject(int index) {
    projects.removeAt(index);
    notifyListeners();
  }

  void addAchievement(AchievementItem item) {
    achievements.add(item);
    notifyListeners();
  }

  void removeAchievement(int index) {
    achievements.removeAt(index);
    notifyListeners();
  }

  // ── Core Logic ─────────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (!isReadOnly) await _loadVisibility();
    await loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();
    try {
      if (isReadOnly) {
        // Viewing someone else
        final res = await UserHelper.fetchUserById(_viewUserId!);
        if (res.success && res.data != null) {
          final UserResponse d = res.data!; // Explicit type
          _mapCommonFields(d);
          // fetchUserById usually doesn't return professional lists, 
          // but we reset them to be safe
          experiences = [];
          projects = [];
          achievements = [];
        }
      } else {
        // Viewing self
        final res = await UserHelper.getProfile();
        if (res.success && res.data != null) {
          final ProfileRes d = res.data!; // Explicit type
          _mapCommonFields(d);
          
          // These fields exist on ProfileRes
          experiences = List<ExperienceItem>.from(d.experiences);
          projects = List<ProjectItem>.from(d.projects);
          achievements = List<AchievementItem>.from(d.achievements);
          queriesCreated = d.queriesCreated;
        }
      }
    } catch (e) {
      error = e.toString();
      debugPrint("Load Profile Error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // Helper to map fields that exist in BOTH UserResponse and ProfileRes
  void _mapCommonFields(dynamic d) {
    username = d.username ?? '';
    bio = d.bio ?? '';
    email = d.email ?? '';
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
    latitude = d.latitude ?? 0.0;
    longitude = d.longitude ?? 0.0;
    
    skills = List<String>.from(d.skills ?? []);
    interests = List<String>.from(d.interests ?? []);
    hobbies = List<String>.from(d.hobbies ?? []);
  } 
  Future<bool> saveProfile(File? image) async {
    isSaving = true;
    notifyListeners();
    
    final req = ProfileUpdateReq(
      username: username,
      bio: bio,
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
      experiences: experiences,
      projects: projects,
      achievements: achievements,
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
