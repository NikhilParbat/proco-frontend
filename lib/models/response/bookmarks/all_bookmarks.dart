import 'dart:convert';

List<AllBookmark> allBookmarkFromJson(String str) {
  final decoded = json.decode(str);

  final list = (decoded is Map && decoded.containsKey('data'))
      ? decoded['data'] as List
      : decoded as List;

  return list
      .map((e) => AllBookmark.fromJson(e as Map<String, dynamic>))
      .toList();
}

class AllBookmark {
  AllBookmark({required this.id, required this.job, this.createdAt});

  factory AllBookmark.fromJson(Map<String, dynamic> json) => AllBookmark(
    id: json['id'] ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'])
        : null,

    // ✅ NEW BACKEND STRUCTURE
    job: Job.fromJson(json['job'] ?? {}),
  );

  final String id;
  final Job job;
  final DateTime? createdAt;
}

class Job {
  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.state,
    required this.country,

    this.description = '',
    this.salary = '',
    this.period = '',
    this.contract = '',
    this.experienceLevel = '',
    this.fieldDegree = '',
    this.languagePreference = '',
    this.domain = '',
    this.opportunityType = '',
    this.imageUrl = '',
    this.hiring = false,

    this.skills = const [],
    this.requirements = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'] ?? '',

    title: json['title'] ?? '',

    company: json['company'] ?? '',

    city: json['city'] ?? '',

    state: json['state'] ?? '',

    country: json['country'] ?? '',

    description: json['description'] ?? '',

    salary: json['salary'] ?? '',

    period: json['period'] ?? '',

    contract: json['contract'] ?? '',

    experienceLevel: json['experienceLevel'] ?? '',

    fieldDegree: json['fieldDegree'] ?? '',

    languagePreference: json['languagePreference'] ?? '',

    domain: json['domain'] ?? '',

    opportunityType: json['opportunityType'] ?? '',

    imageUrl: json['imageUrl'] ?? '',

    hiring: json['isActive'] ?? json['hiring'] ?? false,

    skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],

    requirements:
        (json['requirements'] as List?)?.map((e) => e.toString()).toList() ??
        [],
  );

  final String id;

  final String title;

  final String company;

  final String city;

  final String state;

  final String country;

  final String description;

  final String salary;

  final String period;

  final String contract;

  final String experienceLevel;

  final String fieldDegree;

  final String languagePreference;

  final String domain;

  final String opportunityType;

  final String imageUrl;

  final bool hiring;

  final List<String> skills;

  final List<String> requirements;

  // ✅ Computed location helper
  String get location {
    final parts = [city, state, country].where((e) => e.isNotEmpty).toList();

    return parts.join(', ');
  }

  // ✅ Salary formatter helper
  String get salaryText {
    if (salary.isEmpty) return '';

    if (period.isEmpty) return salary;

    return '$salary · $period';
  }

  // ✅ Company fallback
  String get companyText {
    if (company.trim().isEmpty) {
      return 'Unknown Company';
    }

    return company;
  }

  // ✅ Has image helper
  bool get hasImage {
    return imageUrl.trim().isNotEmpty;
  }
}
