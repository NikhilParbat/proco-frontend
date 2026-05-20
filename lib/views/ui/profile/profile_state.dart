import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/models/response/auth/profile_model.dart';

class ProfileEditState extends ChangeNotifier {
  // Data Fields
  String username = '',
      bio = '',
      email = '',
      phone = '',
      gender = '',
      city = '',
      state = '',
      country = '';
  String profileImageUrl = '', dob = '', userType = '';
  String linkedInUrl = '', gitHubUrl = '', twitterUrl = '', portfolioUrl = '';
  String workStyle = '', communicationStyle = '';
  double latitude = 0.0, longitude = 0.0;

  List<String> skills = [], interests = [], hobbies = [];
  List<ExperienceItem> experiences = [];
  List<ProjectItem> projects = [];
  List<AchievementItem> achievements = [];
  List<LinkItem> links = [];
  List<EducationItem> education = []; // Updated to match UserResponse
  int queriesCreated = 0;

  bool showEmail = true,
      showPhone = true,
      showGender = true,
      showDob = true,
      showCollege =
          true, // Retained configuration flag for visibility UI
      showSkills = true,
      showLinkedIn = true,
      showGitHub = true,
      showTwitter = true,
      showPortfolio = true;

  // Visibility Flags and Status
  bool isLoading = true;
  bool isSaving = false;
  bool _isPrivateInfoVisible = false;
  bool get isPrivateInfoVisible => _isPrivateInfoVisible;
  String? error;

  final String? _viewUserId;
  bool get isReadOnly => _viewUserId != null;

  ProfileEditState({String? viewUserId}) : _viewUserId = viewUserId {
    _init();
  }

  void initialPrivacySetup(bool visibleFromServer) {
    _isPrivateInfoVisible = visibleFromServer;
    notifyListeners();
  }

  Future<void> updatePrivacyPreference(bool newValue) async {
    _isPrivateInfoVisible = newValue;
    notifyListeners(); // Updates the UI instantly
  }

  // ── List Management Helpers ──────────────────────────────────────────────

  void setLocation({
    required String city,
    required String state,
    required String country,
    required double latitude,
    required double longitude,
  }) {
    this.city = city;
    this.state = state;
    this.country = country;
    this.latitude = latitude;
    this.longitude = longitude;
    notifyListeners();
  }

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

  // ── Education Helpers ──
  void addEducation(EducationItem item) {
    education.add(item);
    notifyListeners();
  }

  void removeEducation(int index) {
    education.removeAt(index);
    notifyListeners();
  }

  void updateEducation(int index, EducationItem item) {
    education[index] = item;
    notifyListeners();
  }

  // ── Experience Helpers ──
  void addExperience(ExperienceItem item) {
    experiences.add(item);
    notifyListeners();
  }

  void removeExperience(int index) {
    experiences.removeAt(index);
    notifyListeners();
  }

  void updateExperience(int index, ExperienceItem item) {
    experiences[index] = item;
    notifyListeners();
  }

  // ── Project Helpers ──
  void addProject(ProjectItem item) {
    projects.add(item);
    notifyListeners();
  }

  void removeProject(int index) {
    projects.removeAt(index);
    notifyListeners();
  }

  void updateProject(int index, ProjectItem item) {
    projects[index] = item;
    notifyListeners();
  }

  // ── Achievement Helpers ──
  void addAchievement(AchievementItem item) {
    achievements.add(item);
    notifyListeners();
  }

  void removeAchievement(int index) {
    achievements.removeAt(index);
    notifyListeners();
  }

  void updateAchievement(int index, AchievementItem item) {
    achievements[index] = item;
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
        // Viewing someone else — full profile via UserResponse
        final res = await UserHelper.fetchUserById(_viewUserId!);
        if (res.success && res.data != null) {
          final UserResponse d = res.data!;
          _mapCommonFields(d);
          experiences = List<ExperienceItem>.from(d.experiences);
          projects = List<ProjectItem>.from(d.projects);
          achievements = List<AchievementItem>.from(d.achievements);
          education = List<EducationItem>.from(d.education);
          queriesCreated = d.queriesCreated;
        }
      } else {
        // Viewing self
        final res = await UserHelper.getProfile();
        if (res.success && res.data != null) {
          final ProfileRes d = res.data!;
          _mapCommonFields(d);

          experiences = List<ExperienceItem>.from(d.experiences);
          projects = List<ProjectItem>.from(d.projects);
          achievements = List<AchievementItem>.from(d.achievements);
          links = List<LinkItem>.from(d.links);
          queriesCreated = d.queriesCreated;

          // Fallback parsing strategy in case ProfileRes schema uses map representation or direct type mapping
          if (d.education != null) {
            education = (d.education as List)
                .map(
                  (e) => e is EducationItem
                      ? e
                      : EducationItem.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          }
        }
      }
    } catch (e) {
      error = e.toString();
      debugPrint("Load Profile Error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // Maps fields shared safely between UserResponse and ProfileRes
  void _mapCommonFields(dynamic d) {
    username = d.username ?? '';
    bio = d.bio ?? '';
    email = d.email ?? '';
    phone = d.phone ?? '';
    gender = d.gender ?? '';
    city = d.city ?? '';
    state = d.state ?? '';
    country = d.country ?? '';
    profileImageUrl = d.profile ?? '';
    dob = d.dob ?? '';
    userType = d.userType ?? '';
    linkedInUrl = d.linkedInUrl ?? '';
    gitHubUrl = d.gitHubUrl ?? '';
    twitterUrl = d.twitterUrl ?? '';
    portfolioUrl = d.portfolioUrl ?? '';
    workStyle = d.workStyle ?? '';
    communicationStyle = d.communicationStyle ?? '';
    latitude = d.latitude ?? 0.0;
    longitude = d.longitude ?? 0.0;

    skills = List<String>.from(d.skills ?? []);
    interests = List<String>.from(d.interests ?? []);
    hobbies = List<String>.from(d.hobbies ?? []);

    links =
        (d.links as List?)
            ?.map(
              (l) => l is LinkItem
                  ? l
                  : LinkItem.fromJson(l as Map<String, dynamic>),
            )
            .toList() ??
        [];
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
      workStyle: workStyle,
      communicationStyle: communicationStyle,
      experiences: experiences,
      projects: projects,
      achievements: achievements,
      links: links,
      // Note: Ensure your backend's ProfileUpdateReq model supports this education parameter
      education: education,
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
