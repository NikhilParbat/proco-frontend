import 'dart:convert';

String createJobsRequestToJson(CreateJobsRequest data) =>
    json.encode(data.toJson());

class CreateJobsRequest {
  CreateJobsRequest({
    required this.agentId,
    required this.domain,
    required this.opportunityType,
    required this.latitude,
    required this.longitude,
    this.title = '',
    this.company = '',
    this.description = '',
    this.salary = '',
    this.period = '',
    this.hiring = true,
    this.contract = '',
    this.experienceLevel = '',
    this.fieldDegree = '',
    this.languagePreference = '',
    this.requirements = const [],
    this.skills = const [],
    this.imageUrl = '',
    this.city = '',
    this.state = '',
    this.country = '',
  });

  final String agentId;
  final String domain;
  final String opportunityType;
  final String title;
  final String company;
  final String description;
  final String salary;
  final String period;
  final bool hiring;
  final String contract;
  final String experienceLevel;
  final String fieldDegree;
  final String languagePreference;
  final List<String> requirements;
  final List<String> skills;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'domain': domain,
    'opportunityType': opportunityType,
    'title': title,
    'company': company,
    'description': description,
    'salary': salary,
    'period': period,
    'hiring': hiring,
    'contract': contract,
    'experienceLevel': experienceLevel,
    'fieldDegree': fieldDegree,
    'languagePreference': languagePreference,
    'requirements': requirements.map((x) => x).toList(),
    'skills': skills,
    'imageUrl': imageUrl,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'state': state,
    'country': country,
  };
}
