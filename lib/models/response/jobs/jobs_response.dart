import 'dart:convert';

import 'package:flutter/material.dart';

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
  final String city;
  final String state;
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final String domain;
  final String opportunityType;
  final double latitude;
  final double longitude;
  final List<String> matchedUsers;

  JobsResponse({
    required this.id,
    required this.title,
    required this.city,
    required this.state,
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
    required this.createdAt,
    required this.updatedAt,
    this.domain = '',
    this.opportunityType = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.matchedUsers = const [],
  });

  String get location {
    return [city, state, country].where((s) => s.isNotEmpty).join(', ');
  }

  factory JobsResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 RAW JSON KEYS: ${json.keys.toList()}');
    debugPrint('🔍 RAW REQUIREMENTS: ${json['requirements']}');
    return JobsResponse(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
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
      createdAt: json['createdAt'] != null && json['createdAt'] != ''
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null && json['updatedAt'] != ''
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      domain: json['domain'] ?? '',
      opportunityType:
          json['opportunityType'] ?? json['opportunity_type'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      matchedUsers: json['matchedUsers'] != null
          ? List<String>.from(json['matchedUsers'].map((x) => x.toString()))
          : [],
    );
  }

  static List<String> _parseRequirements(dynamic raw) {
    if (raw == null) return [];

    if (raw is String) {
      // Sometimes backends return a JSON-encoded string
      try {
        final decoded = jsonDecode(raw);
        return _parseRequirements(decoded);
      } catch (_) {
        return raw.isNotEmpty ? [raw] : [];
      }
    }

    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              // Try every common column name your backend might use
              return (e['requirement'] ??
                      e['text'] ??
                      e['value'] ??
                      e['name'] ??
                      e['description'] ??
                      '')
                  .toString();
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
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
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'domain': domain,
    'opportunityType': opportunityType,
    'latitude': latitude,
    'longitude': longitude,
    'matchedUsers': matchedUsers,
  };
}
