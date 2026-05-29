import 'package:proco/models/request/auth/profile_update_model.dart';

class UserResponse {
  final String id;
  final String username;
  final String? bio;
  final String email;
  final String? phone;
  final bool? isAdmin;
  final bool? isAgent;
  final String? profile;
  final String? gender;
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
  final String? workStyle;
  final String? communicationStyle;
  final String? provider;
  final bool? isFirstTimeUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> skills;
  final List<String> interests;
  final List<String> hobbies;
  final int queriesCreated;
  final int successfulMatches;
  final List<ExperienceItem> experiences;
  final List<ProjectItem> projects;
  final List<AchievementItem> achievements;
  final List<LinkItem> links;
  final List<EducationItem> education;

  UserResponse({
    required this.id,
    required this.username,
    this.bio,
    required this.email,
    this.phone,
    this.isAdmin,
    this.isAgent,
    this.profile,
    this.gender,
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
    this.workStyle,
    this.communicationStyle,
    this.provider,
    this.isFirstTimeUser,
    this.createdAt,
    this.updatedAt,
    this.education = const [],
    this.skills = const [],
    this.interests = const [],
    this.hobbies = const [],
    this.queriesCreated = 0,
    this.successfulMatches = 0,
    this.experiences = const [],
    this.projects = const [],
    this.achievements = const [],
    this.links = const [],
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'],
      email: json['email'] ?? '',
      phone: json['phone'],
      isAdmin: json['isAdmin'],
      isAgent: json['isAgent'],
      profile: json['profile'],
      gender: json['gender'],
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
      workStyle: json['workStyle'],
      communicationStyle: json['communicationStyle'],
      provider: json['provider'],
      isFirstTimeUser: json['isFirstTimeUser'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : [],
      hobbies: json['hobbies'] != null ? List<String>.from(json['hobbies']) : [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => EducationItem.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      queriesCreated: (json['queriesCreated'] as num?)?.toInt() ?? 0,
      successfulMatches: (json['successfulMatches'] as num?)?.toInt() ?? 0,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((p) => ProjectItem.fromJson(p as Map<String, dynamic>))
              .toList() ?? [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((a) => AchievementItem.fromJson(a as Map<String, dynamic>))
              .toList() ?? [],
      links: (json['links'] as List<dynamic>?)
              ?.map((l) => LinkItem.fromJson(l as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'bio': bio,
      'email': email,
      'phone': phone,
      'isAdmin': isAdmin,
      'isAgent': isAgent,
      'profile': profile,
      'gender': gender,
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
      'workStyle': workStyle,
      'communicationStyle': communicationStyle,
      'provider': provider,
      'isFirstTimeUser': isFirstTimeUser,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'skills': skills,
      'interests': interests,
      'hobbies': hobbies,
      'education': education.map((e) => e.toJson()).toList(),
      'queriesCreated': queriesCreated,
      'successfulMatches': successfulMatches,
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
    };
  }

  UserResponse copyWith({
    String? id,
    String? username,
    String? bio,
    String? email,
    String? phone,
    bool? isAdmin,
    bool? isAgent,
    String? profile,
    String? gender,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
    String? dob,
    String? linkedInUrl,
    String? gitHubUrl,
    String? twitterUrl,
    String? portfolioUrl,
    String? userType,
    String? workStyle,
    String? communicationStyle,
    String? provider,
    bool? isFirstTimeUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? skills,
    List<String>? interests,
    List<String>? hobbies,
    List<EducationItem>? education,
    List<LinkItem>? links,
  }) {
    return UserResponse(
      id: id ?? this.id,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isAdmin: isAdmin ?? this.isAdmin,
      isAgent: isAgent ?? this.isAgent,
      profile: profile ?? this.profile,
      gender: gender ?? this.gender,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      gitHubUrl: gitHubUrl ?? this.gitHubUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      userType: userType ?? this.userType,
      workStyle: workStyle ?? this.workStyle,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      provider: provider ?? this.provider,
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      hobbies: hobbies ?? this.hobbies,
      education: education ?? this.education,
      links: links ?? this.links,
    );
  }
}
