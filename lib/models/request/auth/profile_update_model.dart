import 'package:proco/models/request/auth/professional_items.dart';

class ProfileUpdateReq {
  final String username;
  final String city;
  final String state;
  final String country;
  final String phone;
  final String college;
  final String branch;
  final String? gender;
  final String dob;
  final String userType;
  final String linkedInUrl;
  final String gitHubUrl;
  final String twitterUrl;
  final String portfolioUrl;
  final double latitude;
  final double longitude;
  final List<String> skills;
  final List<String> interests;
  final List<String> hobbies;
  final List<ExperienceItem> experiences;
  final List<ProjectItem> projects;
  final List<AchievementItem> achievements;

  ProfileUpdateReq({
    required this.username,
    this.city = '',
    this.state = '',
    this.country = '',
    this.phone = '',
    this.college = '',
    this.branch = '',
    this.gender,
    this.dob = '',
    this.userType = '',
    this.linkedInUrl = '',
    this.gitHubUrl = '',
    this.twitterUrl = '',
    this.portfolioUrl = '',
    this.latitude = 0,
    this.longitude = 0,
    this.skills = const [],
    this.interests = const [],
    this.hobbies = const [],
    this.experiences = const [],
    this.projects = const [],
    this.achievements = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'city': city,
      'state': state,
      'country': country,
      'phone': phone,
      'college': college,
      'branch': branch,
      'gender': gender,
      'dob': dob,
      'userType': userType,
      'linkedInUrl': linkedInUrl,
      'gitHubUrl': gitHubUrl,
      'twitterUrl': twitterUrl,
      'portfolioUrl': portfolioUrl,
      'latitude': latitude,
      'longitude': longitude,
      'skills': skills,
      'interests': interests,
      'hobbies': hobbies,
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };
  }

  ProfileUpdateReq copyWith({
    String? username,
    String? city,
    String? state,
    String? country,
    String? phone,
    String? college,
    String? branch,
    String? gender,
    String? dob,
    String? userType,
    String? linkedInUrl,
    String? gitHubUrl,
    String? twitterUrl,
    String? portfolioUrl,
    double? latitude,
    double? longitude,
    List<String>? skills,
    List<String>? interests,
    List<String>? hobbies,
    List<ExperienceItem>? experiences,
    List<ProjectItem>? projects,
    List<AchievementItem>? achievements,
  }) {
    return ProfileUpdateReq(
      username: username ?? this.username,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      college: college ?? this.college,
      branch: branch ?? this.branch,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      userType: userType ?? this.userType,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      gitHubUrl: gitHubUrl ?? this.gitHubUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      hobbies: hobbies ?? this.hobbies,
      experiences: experiences ?? this.experiences,
      projects: projects ?? this.projects,
      achievements: achievements ?? this.achievements,
    );
  }
}
