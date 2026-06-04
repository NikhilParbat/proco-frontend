import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proco/controllers/profile_provider.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/models/response/auth/profile_model.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditState extends ChangeNotifier {
  final ProfileNotifier _notifier;

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
  List<EducationItem> education = [];
  int queriesCreated = 0;
  int successfulMatches = 0;

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
  bool _isPrivateInfoVisible = false;
  bool get isPrivateInfoVisible => _isPrivateInfoVisible;
  String? error;

  final String? _viewUserId;
  bool get isReadOnly => _viewUserId != null;

  ProfileEditState({required ProfileNotifier notifier, String? viewUserId})
    : _notifier = notifier,
      _viewUserId = viewUserId {
    _init();
  }

  void initialPrivacySetup(bool visibleFromServer) {
    _isPrivateInfoVisible = visibleFromServer;
    notifyListeners();
  }

  Future<void> updatePrivacyPreference(bool newValue) async {
    _isPrivateInfoVisible = newValue;
    notifyListeners();
  }

  // ── Location ──────────────────────────────────────────────────────────────

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

  // ── Skills / Interests / Hobbies ─────────────────────────────────────────

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

  void addHobby(String hobby) {
    if (hobby.isNotEmpty && !hobbies.contains(hobby)) {
      hobbies.add(hobby);
      notifyListeners();
    }
  }

  void removeHobby(String hobby) {
    hobbies.remove(hobby);
    notifyListeners();
  }

  // ── Education ─────────────────────────────────────────────────────────────

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

  // ── Experience ────────────────────────────────────────────────────────────

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

  // ── Projects ──────────────────────────────────────────────────────────────

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

  // ── Achievements ──────────────────────────────────────────────────────────

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

  void addLink(LinkItem item) {
    if (links.length >= 6) return;
    links.add(item);
    notifyListeners();
  }

  void removeLink(int index) {
    links.removeAt(index);
    notifyListeners();
  }

  // ── Core Logic ────────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (!isReadOnly) await _loadVisibility();
    await loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (isReadOnly) {
        final user = await _notifier.fetchUserById(_viewUserId!);
        if (user != null) _mapFromUserResponse(user);
      } else {
        await _notifier.getProfile();
        final profile = _notifier.profile;
        if (profile != null) {
          _mapFromProfileRes(profile);
        } else {
          error = _notifier.profileError;
        }
      }
    } catch (e) {
      error = e.toString();
      debugPrint('loadProfile error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _mapFromProfileRes(ProfileRes d) {
    username = d.username;
    bio = d.bio ?? '';
    email = d.email;
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
    skills = List<String>.from(d.skills);
    interests = List<String>.from(d.interests);
    hobbies = List<String>.from(d.hobbies);
    education = List<EducationItem>.from(d.education);
    experiences = List<ExperienceItem>.from(d.experiences);
    projects = List<ProjectItem>.from(d.projects);
    achievements = List<AchievementItem>.from(d.achievements);
    links = List<LinkItem>.from(d.links);
    queriesCreated = d.queriesCreated;
    successfulMatches = d.successfulMatches;
  }

  void _mapFromUserResponse(UserResponse d) {
    username = d.username;
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
    latitude = (d.latitude ?? 0.0).toDouble();
    longitude = (d.longitude ?? 0.0).toDouble();
    skills = List<String>.from(d.skills);
    interests = List<String>.from(d.interests);
    hobbies = List<String>.from(d.hobbies);
    education = List<EducationItem>.from(d.education);
    experiences = List<ExperienceItem>.from(d.experiences);
    projects = List<ProjectItem>.from(d.projects);
    achievements = List<AchievementItem>.from(d.achievements);
    links = List<LinkItem>.from(d.links);
    queriesCreated = d.queriesCreated;
    successfulMatches = d.successfulMatches;
  }

  Future<bool> saveProfile(XFile? image) async {
    isSaving = true;
    notifyListeners();

    final req = ProfileUpdateReq(
      username: username,
      bio: bio,
      city: city,
      state: state,
      country: country,
      phone: phone,
      gender: gender.isEmpty ? null : gender,
      dob: dob,
      userType: userType,
      skills: skills,
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
      education: education,
    );

    final success = await _notifier.updateProfile(req, image);

    isSaving = false;
    notifyListeners();
    return success;
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
