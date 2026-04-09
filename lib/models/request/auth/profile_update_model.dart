import 'dart:convert';

ProfileUpdateReq profileUpdateReqFromJson(String str) =>
    ProfileUpdateReq.fromJson(json.decode(str));

String profileUpdateReqToJson(ProfileUpdateReq data) =>
    json.encode(data.toJson());

class ProfileUpdateReq {
  ProfileUpdateReq({
    this.city = "",
    this.state = "",
    this.country = "",
    required this.phone,
    this.profile,
    required this.skills,
    this.college = "",
    this.branch = "",
    this.gender,
    this.age = "",
    this.linkedInUrl = "",
    this.gitHubUrl = "",
    this.twitterUrl = "",
    this.portfolioUrl = "",
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory ProfileUpdateReq.fromJson(Map<String, dynamic> json) =>
      ProfileUpdateReq(
        city: json['city'],
        state: json['state'],
        country: json['country'],
        phone: json['phone'],
        profile: json['profile'],
        skills: List<String>.from(json['skills'].map((x) => x)),
        college: json['college'] ?? "",
        branch: json['branch'] ?? "",
        gender: json['gender'],
        age: json['age'] ?? "",
        linkedInUrl: json['linkedInUrl'] ?? "",
        gitHubUrl: json['gitHubUrl'] ?? "",
        twitterUrl: json['twitterUrl'] ?? "",
        portfolioUrl: json['portfolioUrl'] ?? "",
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      );

  String city;
  String state;
  String country;
  String phone;
  String? profile;
  List<String> skills;
  String college;
  String branch;
  String? gender;
  String age;
  String linkedInUrl;
  String gitHubUrl;
  String twitterUrl;
  String portfolioUrl;
  double latitude;
  double longitude;

  Map<String, dynamic> toJson() => {
        'city': city,
        'state': state,
        'country': country,
        'phone': phone,
        'profile': profile,
        'skills': List<dynamic>.from(skills.map((x) => x)),
        'college': college,
        'branch': branch,
        if (gender != null) 'gender': gender,
        'age': age,
        'linkedInUrl': linkedInUrl,
        'gitHubUrl': gitHubUrl,
        'twitterUrl': twitterUrl,
        'portfolioUrl': portfolioUrl,
        'latitude': latitude,
        'longitude': longitude,
      };
}
