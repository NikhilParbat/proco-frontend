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
    this.requirements = const [],
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
  final List<String> requirements;
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
        'requirements': requirements.map((x) => x).toList(),
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'state': state,
        'country': country,
      };
}
