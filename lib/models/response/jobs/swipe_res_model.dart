import 'dart:convert';
import 'package:proco/models/request/auth/profile_update_model.dart';

List<SwipedRes> swipedResListFromJson(String str) {
  final decoded = json.decode(str);
  if (decoded['success'] != true) {
    throw Exception(decoded['message'] ?? "Failed to fetch swiped users");
  }
  final List data = decoded['data'] ?? [];
  return data.map((e) => SwipedRes.fromJson(e)).toList();
}

class SwipedRes {
  final String id;
  final String username;
  final String bio;
  final String profile;
  final String gender;
  final String dob;
  final String city;
  final String country;
  final List<String> skills;
  final List<EducationItem> education;
  final List<LinkItem> links;

  SwipedRes({
    required this.id,
    required this.username,
    required this.bio,
    required this.profile,
    required this.gender,
    required this.dob,
    required this.city,
    required this.country,
    required this.skills,
    this.education = const [],
    this.links = const [],
  });

  factory SwipedRes.fromJson(Map<String, dynamic> json) {
    return SwipedRes(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      profile: json['profile'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => EducationItem.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      links: (json['links'] as List<dynamic>?)
              ?.map((l) => LinkItem.fromJson(l as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'bio': bio,
        'profile': profile,
        'gender': gender,
        'dob': dob,
        'city': city,
        'country': country,
        'skills': skills,
        'education': education.map((e) => e.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
      };
}