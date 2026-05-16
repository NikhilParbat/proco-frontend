import 'package:proco/models/request/auth/profile_update_model.dart';

class UserResponse {
  final String id;
  final String username;
  final String? bio;
  final String email;
  final String? phone;
  final bool? isAdmin;
  final bool? isAgent;
  final String? profile;
  final String? college;
  final String? gender;
  final String? branch;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? dob;
  final String? linkedInUrl;
  final String? gitHubUrl;
  final String? twitterUrl;
  final String? portfolioUrl;
  final String? userType;
  final String? classOf;
  final String? cgpa;
  final String? workStyle;
  final String? communicationStyle;
  final String? provider;
  final bool? isFirstTimeUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> skills;
  final List<String> interests;
  final List<String> hobbies;
  final List<LinkItem> links;

  UserResponse({
    required this.id,
    required this.username,
    this.bio,
    required this.email,
    this.phone,
    this.isAdmin,
    this.isAgent,
    this.profile,
    this.college,
    this.gender,
    this.branch,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.dob,
    this.linkedInUrl,
    this.gitHubUrl,
    this.twitterUrl,
    this.portfolioUrl,
    this.userType,
    this.classOf,
    this.cgpa,
    this.workStyle,
    this.communicationStyle,
    this.provider,
    this.isFirstTimeUser,
    this.createdAt,
    this.updatedAt,
    this.skills = const [],
    this.interests = const [],
    this.hobbies = const [],
    this.links = const [],
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'],
      email: json['email'] ?? '',
      phone: json['phone'],
      isAdmin: json['isAdmin'],
      isAgent: json['isAgent'],
      profile: json['profile'],
      college: json['college'],
      gender: json['gender'],
      branch: json['branch'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      dob: json['dob'],
      linkedInUrl: json['linkedInUrl'],
      gitHubUrl: json['gitHubUrl'],
      twitterUrl: json['twitterUrl'],
      portfolioUrl: json['portfolioUrl'],
      userType: json['userType'],
      classOf: json['classOf'],
      cgpa: json['cgpa'],
      workStyle: json['workStyle'],
      communicationStyle: json['communicationStyle'],
      provider: json['provider'],
      isFirstTimeUser: json['isFirstTimeUser'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : [],
      hobbies: json['hobbies'] != null ? List<String>.from(json['hobbies']) : [],
      links: (json['links'] as List<dynamic>?)
              ?.map((l) => LinkItem.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'bio': bio,
      'email': email,
      'phone': phone,
      'isAdmin': isAdmin,
      'isAgent': isAgent,
      'profile': profile,
      'college': college,
      'gender': gender,
      'branch': branch,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'dob': dob,
      'linkedInUrl': linkedInUrl,
      'gitHubUrl': gitHubUrl,
      'twitterUrl': twitterUrl,
      'portfolioUrl': portfolioUrl,
      'userType': userType,
      'classOf': classOf,
      'cgpa': cgpa,
      'workStyle': workStyle,
      'communicationStyle': communicationStyle,
      'provider': provider,
      'isFirstTimeUser': isFirstTimeUser,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'skills': skills,
      'interests': interests,
      'hobbies': hobbies,
      'links': links.map((l) => l.toJson()).toList(),
    };
  }

  UserResponse copyWith({
    String? id,
    String? username,
    String? bio,
    String? email,
    String? phone,
    bool? isAdmin,
    bool? isAgent,
    String? profile,
    String? college,
    String? gender,
    String? branch,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
    String? dob,
    String? linkedInUrl,
    String? gitHubUrl,
    String? twitterUrl,
    String? portfolioUrl,
    String? userType,
    String? classOf,
    String? cgpa,
    String? workStyle,
    String? communicationStyle,
    String? provider,
    bool? isFirstTimeUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? skills,
    List<String>? interests,
    List<String>? hobbies,
    List<LinkItem>? links,
  }) {
    return UserResponse(
      id: id ?? this.id,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isAdmin: isAdmin ?? this.isAdmin,
      isAgent: isAgent ?? this.isAgent,
      profile: profile ?? this.profile,
      college: college ?? this.college,
      gender: gender ?? this.gender,
      branch: branch ?? this.branch,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      gitHubUrl: gitHubUrl ?? this.gitHubUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      userType: userType ?? this.userType,
      classOf: classOf ?? this.classOf,
      cgpa: cgpa ?? this.cgpa,
      workStyle: workStyle ?? this.workStyle,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      provider: provider ?? this.provider,
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      hobbies: hobbies ?? this.hobbies,
      links: links ?? this.links,
    );
  }
}
