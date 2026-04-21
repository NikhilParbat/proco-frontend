import 'dart:convert';

GetJobRes getJobResFromJson(String str) {
  final decoded = json.decode(str);

  if (decoded['success'] != true) {
    throw Exception(decoded['message'] ?? "Failed to fetch job");
  }

  return GetJobRes.fromJson(decoded['data'] ?? {});
}

String getJobResToJson(GetJobRes data) => json.encode(data.toJson());

class GetJobRes {
  final String jobId;
  final String title;
  final String city;
  final String? state;
  final String country;
  final String company;
  final bool hiring;
  final String description;
  final String salary;
  final String period;
  final String contract;
  final List<String> requirements;
  final String imageUrl;
  final String agentId;
  final String domain;
  final String opportunityType;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  GetJobRes({
    required this.jobId,
    required this.title,
    required this.city,
    this.state,
    required this.country,
    required this.company,
    required this.hiring,
    required this.description,
    required this.salary,
    required this.period,
    required this.contract,
    required this.requirements,
    required this.imageUrl,
    required this.agentId,
    this.domain = '',
    this.opportunityType = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get location {
    final parts = [city, state ?? '', country].where((s) => s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  factory GetJobRes.fromJson(Map<String, dynamic> json) {
    return GetJobRes(
      jobId: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      country: json['country'] ?? '',
      company: json['company'] ?? '',
      hiring: json['hiring'] ?? false,
      description: json['description'] ?? '',
      salary: json['salary'] ?? '',
      period: json['period'] ?? '',
      contract: json['contract'] ?? '',
      requirements: _parseRequirements(json['requirements']),
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      agentId: json['agentId'] ?? json['agent_id'] ?? '',
      domain: json['domain'] ?? '',
      opportunityType: json['opportunityType'] ?? json['opportunity_type'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static List<String> _parseRequirements(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) return (e['requirement'] ?? e['text'] ?? '').toString();
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
        'id': jobId,
        'title': title,
        'city': city,
        'state': state,
        'country': country,
        'company': company,
        'hiring': hiring,
        'description': description,
        'salary': salary,
        'period': period,
        'contract': contract,
        'requirements': requirements,
        'imageUrl': imageUrl,
        'agentId': agentId,
        'domain': domain,
        'opportunityType': opportunityType,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
