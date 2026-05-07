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
        company: json['company'] as String? ?? '',
        position: json['position'] as String? ?? '',
        description: json['description'] as String? ?? '',
        dateRange: json['dateRange'] as String? ?? '',
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

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
        name: json['name'] as String? ?? '',
        domain: json['domain'] as String? ?? '',
        description: json['description'] as String? ?? '',
        technologies: json['technologies'] != null
            ? List<String>.from(json['technologies'] as List)
            : [],
        sourceUrl: json['sourceUrl'] as String? ?? '',
      );

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

  const AchievementItem({required this.title, this.subtitle = ''});

  factory AchievementItem.fromJson(Map<String, dynamic> json) => AchievementItem(
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
      };
}
