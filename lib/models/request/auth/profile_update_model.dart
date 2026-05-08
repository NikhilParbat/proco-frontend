import 'dart:convert';

class ProfileUpdateReq {
  final String username;
  final String bio;
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
    this.bio = '',
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
    this.latitude = 0.0,
    this.longitude = 0.0,
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
      'bio': bio,
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
}

// ── Item Classes matching your DB Schema ────────────────────────────────────

class ExperienceItem {
  final String company;
  final String position;
  final String description;
  final String dateRange; // Matches 'date_range' in Drizzle

  ExperienceItem({
    required this.company,
    required this.position,
    this.description = '',
    this.dateRange = '',
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'position': position,
        'description': description,
        'dateRange': dateRange,
      };
}

class ProjectItem {
  final String name;
  final String domain;
  final String description;
  final List<String> technologies; // Encoded as JSON string in DB
  final String sourceUrl; // Matches 'source_url' in Drizzle

  ProjectItem({
    required this.name,
    this.domain = '',
    this.description = '',
    this.technologies = const [],
    this.sourceUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'domain': domain,
        'description': description,
        'technologies': jsonEncode(technologies), // Backend expects stringified array
        'sourceUrl': sourceUrl,
      };
}

class AchievementItem {
  final String title;
  final String subtitle;
  final String icon;

  AchievementItem({
    required this.title,
    this.subtitle = '',
    this.icon = 'star',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
      };
}