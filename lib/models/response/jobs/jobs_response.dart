import 'dart:convert';

List<JobsResponse> jobsResponseFromJson(String str) {
  final decoded = json.decode(str);

  List dataList;
  if (decoded is List) {
    dataList = decoded;
  } else {
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? "Failed to fetch jobs");
    }
    dataList = decoded['data'] ?? [];
  }

  return dataList
      .map((e) => JobsResponse.fromJson(e as Map<String, dynamic>))
      .toList();
}

class JobsResponse {
  final String id;
  final String title;
  final String location;
  final String company;
  final bool hiring;
  final String description;
  final String salary;
  final String period;
  final String contract;
  final List<String> requirements;
  final String imageUrl;
  final String agentId;
  final List<String> swipedUsers;
  final List<String> matchedUsers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String domain;
  final String opportunityType;
  final String city;
  final double latitude;
  final double longitude;

  JobsResponse({
    required this.id,
    required this.title,
    required this.location,
    required this.company,
    required this.hiring,
    required this.description,
    required this.salary,
    required this.period,
    required this.contract,
    required this.requirements,
    required this.imageUrl,
    required this.agentId,
    required this.swipedUsers,
    required this.matchedUsers,
    required this.createdAt,
    required this.updatedAt,
    this.domain = '',
    this.opportunityType = '',
    this.city = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory JobsResponse.fromJson(Map<String, dynamic> json) {
    // 1. Check if location is a Map (new GeoJSON format) or a String (old format)
    final dynamic rawLocation = json['location'];
    
    String displayLocation = "";
    double lat = 0.0;
    double lng = 0.0;
    String extractedCity = json['city'] ?? "";

    if (rawLocation is Map<String, dynamic>) {
      // It's a Map: Extract the city/state and coordinates
      displayLocation = rawLocation['city'] ?? rawLocation['state'] ?? "";
      extractedCity = rawLocation['city'] ?? "";
      
      final List<dynamic>? coordinates = rawLocation['coordinates'];
      if (coordinates != null && coordinates.length >= 2) {
        // MongoDB stores [lng, lat]
        lng = (coordinates[0] as num).toDouble();
        lat = (coordinates[1] as num).toDouble();
      }
    } else if (rawLocation is String) {
      // It's already a String: Use it directly
      displayLocation = rawLocation;
    }

    return JobsResponse(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      // ✅ FIXED: Use the 'displayLocation' string we extracted above
      // instead of 'json['location']' which might be a Map
      location: displayLocation, 
      company: json['company'] ?? '',
      hiring: json['hiring'] ?? false,
      description: json['description'] ?? '',
      salary: json['salary'] ?? '',
      period: json['period'] ?? '',
      contract: json['contract'] ?? '',
      requirements: json['requirements'] != null
          ? List<String>.from(json['requirements'].map((x) => x.toString()))
          : [],
      imageUrl: json['imageUrl'] ?? '',
      agentId: json['agentId'] ?? '',
      swipedUsers: json['swipedUsers'] != null
          ? List<String>.from(json['swipedUsers'].map((x) => x.toString()))
          : [],
      matchedUsers: json['matchedUsers'] != null
          ? List<String>.from(json['matchedUsers'].map((x) => x.toString()))
          : [],
      createdAt: json['createdAt'] != null && json['createdAt'] != ''
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null && json['updatedAt'] != ''
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      domain: json['domain'] ?? '',
      opportunityType: json['opportunityType'] ?? '',
      city: extractedCity,
      longitude: lng,
      latitude: lat,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'location': location,
        'company': company,
        'hiring': hiring,
        'description': description,
        'salary': salary,
        'period': period,
        'contract': contract,
        'requirements': requirements,
        'imageUrl': imageUrl,
        'agentId': agentId,
        'swipedUsers': swipedUsers,
        'matchedUsers': matchedUsers,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'domain': domain,
        'opportunityType': opportunityType,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      };
}