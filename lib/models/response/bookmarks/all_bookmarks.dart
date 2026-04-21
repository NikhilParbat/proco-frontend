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
  AllBookmark({
    required this.id,
    required this.job,
    this.createdAt,
  });

  factory AllBookmark.fromJson(Map<String, dynamic> json) => AllBookmark(
        id: json['id'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        job: Job.fromJson(json),
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
    this.opportunityType = '',
    this.imageUrl = '',
    this.salary = '',
    this.period = '',
    this.contract = '',
    this.hiring = false,
  });

  // Backend sends flat fields on the bookmark row (joined from jobs table)
  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['jobId'] ?? '',
        title: json['title'] ?? '',
        company: json['company'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        country: json['country'] ?? '',
        opportunityType: json['opportunityType'] ?? '',
        // Fields not returned by Postgres join — default to empty/false
        imageUrl: json['imageUrl'] ?? '',
        salary: json['salary'] ?? '',
        period: json['period'] ?? '',
        contract: json['contract'] ?? '',
        hiring: json['hiring'] ?? false,
      );

  final String id;
  final String title;
  final String company;
  final String city;
  final String state;
  final String country;
  final String opportunityType;
  final String imageUrl;
  final String salary;
  final String period;
  final String contract;
  final bool hiring;

  // Computed from city/state/country instead of parsing GeoJSON
  String get location {
    final parts = [city, state, country].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : '';
  }
}
