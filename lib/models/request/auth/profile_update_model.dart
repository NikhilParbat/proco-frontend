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
  final String classOf;
  final String cgpa;
  final String workStyle;
  final String communicationStyle;
  final List<String> skills;
  final List<String> interests;
  final List<String> hobbies;
  final List<ExperienceItem> experiences;
  final List<ProjectItem> projects;
  final List<AchievementItem> achievements;
  final List<LinkItem> links;

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
    this.classOf = '',
    this.cgpa = '',
    this.workStyle = '',
    this.communicationStyle = '',
    this.skills = const [],
    this.interests = const [],
    this.hobbies = const [],
    this.experiences = const [],
    this.projects = const [],
    this.achievements = const [],
    this.links = const [],
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
      'classOf': classOf,
      'cgpa': cgpa,
      'workStyle': workStyle,
      'communicationStyle': communicationStyle,
      'skills': skills,
      'interests': interests,
      'hobbies': hobbies,
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
    };
  }
}

// ── Item Classes matching your DB Schema ────────────────────────────────────
class ExperienceItem {
  final String company;
  final String position;
  final String description;
  final String dateRange;

  ExperienceItem({
    required this.company,
    required this.position,
    this.description = '',
    this.dateRange = '',
  });

  factory ExperienceItem.fromJson(Map<String, dynamic> json) {
    return ExperienceItem(
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      description: json['description'] ?? '',
      dateRange: json['dateRange'] ?? '',
    );
  }

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
  final List<String> technologies;
  final String sourceUrl;

  ProjectItem({
    required this.name,
    this.domain = '',
    this.description = '',
    this.technologies = const [],
    this.sourceUrl = '',
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      name: json['name'] ?? '',
      domain: json['domain'] ?? '',
      description: json['description'] ?? '',
      technologies: json['technologies'] is String
          ? List<String>.from(jsonDecode(json['technologies']))
          : List<String>.from(json['technologies'] ?? []),
      sourceUrl: json['sourceUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'domain': domain,
    'description': description,
    'technologies': technologies,
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

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: json['icon'] ?? 'star',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'icon': icon,
  };
}

class LinkItem {
  final String label;
  final String url;

  LinkItem({required this.label, required this.url});

  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(
    label: json['label'] ?? '',
    url: json['url'] ?? '',
  );

  Map<String, dynamic> toJson() => {'label': label, 'url': url};
}
