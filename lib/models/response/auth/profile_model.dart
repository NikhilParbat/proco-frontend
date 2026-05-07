import 'package:proco/models/request/auth/professional_items.dart';

class ProfileRes {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final bool? isAdmin;
  final bool? isAgent;
  final String? profile;
  final String? college;
  final String? gender;
  final String? branch;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? dob;
  final String? linkedInUrl;
  final String? gitHubUrl;
  final String? twitterUrl;
  final String? portfolioUrl;
  final String? userType;
  final String? provider;
  final bool? isFirstTimeUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> skills;
  final List<String> interests;
  final List<String> hobbies;
  final int queriesCreated;
  final List<ExperienceItem> experiences;
  final List<ProjectItem> projects;
  final List<AchievementItem> achievements;

  ProfileRes({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.isAdmin,
    this.isAgent,
    this.profile,
    this.college,
    this.gender,
    this.branch,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.dob,
    this.linkedInUrl,
    this.gitHubUrl,
    this.twitterUrl,
    this.portfolioUrl,
    this.userType,
    this.provider,
    this.isFirstTimeUser,
    this.createdAt,
    this.updatedAt,
    this.skills = const [],
    this.interests = const [],
    this.hobbies = const [],
    this.queriesCreated = 0,
    this.experiences = const [],
    this.projects = const [],
    this.achievements = const [],
  });

  factory ProfileRes.fromJson(Map<String, dynamic> json) {
    return ProfileRes(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isAdmin: json['isAdmin'],
      isAgent: json['isAgent'],
      profile: json['profile'],
      college: json['college'],
      gender: json['gender'],
      branch: json['branch'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      dob: json['dob'],
      linkedInUrl: json['linkedInUrl'],
      gitHubUrl: json['gitHubUrl'],
      twitterUrl: json['twitterUrl'],
      portfolioUrl: json['portfolioUrl'],
      userType: json['userType'],
      provider: json['provider'],
      isFirstTimeUser: json['isFirstTimeUser'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      hobbies: json['hobbies'] != null
          ? List<String>.from(json['hobbies'])
          : [],
      queriesCreated: (json['queriesCreated'] as num?)?.toInt() ?? 0,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((p) => ProjectItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((a) => AchievementItem.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'isAdmin': isAdmin,
      'isAgent': isAgent,
      'profile': profile,
      'college': college,
      'gender': gender,
      'branch': branch,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'dob': dob,
      'linkedInUrl': linkedInUrl,
      'gitHubUrl': gitHubUrl,
      'twitterUrl': twitterUrl,
      'portfolioUrl': portfolioUrl,
      'userType': userType,
      'provider': provider,
      'isFirstTimeUser': isFirstTimeUser,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'skills': skills,
      'interests': interests,
      'hobbies': hobbies,
      'queriesCreated': queriesCreated,
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };
  }
}
