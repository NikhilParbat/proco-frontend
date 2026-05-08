import 'dart:convert';

class ExperienceItem {
  final String company;
  final String position;
  final String description;
  final String dateRange;

  const ExperienceItem({
    required this.company,
    required this.position,
    this.description = '',
    this.dateRange = '',
  });

  factory ExperienceItem.fromJson(Map<String, dynamic> json) => ExperienceItem(
        company: json['company']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        dateRange: json['dateRange']?.toString() ?? '',
      );

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

  const ProjectItem({
    required this.name,
    this.domain = '',
    this.description = '',
    this.technologies = const [],
    this.sourceUrl = '',
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    // Robust parsing for the technologies field (handles List or JSON String)
    List<String> techList = [];
    if (json['technologies'] is List) {
      techList = List<String>.from(json['technologies']);
    } else if (json['technologies'] is String && json['technologies'].isNotEmpty) {
      try {
        techList = List<String>.from(jsonDecode(json['technologies']));
      } catch (_) {
        techList = [];
      }
    }

    return ProjectItem(
      name: json['name']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      technologies: techList,
      sourceUrl: json['sourceUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'domain': domain,
        'description': description,
        'technologies': technologies, // Request model will handle stringification if needed
        'sourceUrl': sourceUrl,
      };
}

class AchievementItem {
  final String title;
  final String subtitle;
  final String icon; // Added to match Drizzle schema

  const AchievementItem({
    required this.title, 
    this.subtitle = '', 
    this.icon = 'star',
  });

  factory AchievementItem.fromJson(Map<String, dynamic> json) => AchievementItem(
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        icon: json['icon']?.toString() ?? 'star',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
      };
}