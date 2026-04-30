import 'dart:convert';

SignupRequestModel signupRequestModelFromJson(String str) =>
    SignupRequestModel.fromJson(json.decode(str));

String signupRequestModelToJson(SignupRequestModel data) =>
    json.encode(data.toJson());

class SignupRequestModel {
  SignupRequestModel({
    required this.username,
    required this.email,
    required this.password,
    this.phone,
    this.profile,
    this.skills = const [],
    this.college,
    this.branch,
    this.gender,
    this.dob,
    this.userType,
    this.linkedInUrl,
    this.gitHubUrl,
    this.twitterUrl,
    this.portfolioUrl,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
  });

  String username;
  String email;
  String password;

  final String? phone;
  final String? profile;

  final List<String> skills;

  final String? college;
  final String? branch;
  final String? gender;
  final String? dob;

  final String? userType;

  final String? linkedInUrl;
  final String? gitHubUrl;
  final String? twitterUrl;
  final String? portfolioUrl;

  double? latitude;
  double? longitude;

  final String? city;
  final String? state;
  final String? country;

  factory SignupRequestModel.fromJson(Map<String, dynamic> json) =>
      SignupRequestModel(
        username: json['username'],
        email: json['email'],
        password: json['password'],
        phone: json['phone'],
        profile: json['profile'],
        skills: List<String>.from(json['skills'] ?? []),
        college: json['college'],
        branch: json['branch'],
        gender: json['gender'],
        dob: json['dob'],
        userType: json['userType'],
        linkedInUrl: json['linkedInUrl'],
        gitHubUrl: json['gitHubUrl'],
        twitterUrl: json['twitterUrl'],
        portfolioUrl: json['portfolioUrl'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        city: json['city'],
        state: json['state'],
        country: json['country'],
      );

  Map<String, dynamic> toJson() => {
    "username": username,
    "email": email,
    "password": password,
    "phone": phone,
    "profile": profile,
    "skills": skills,
    "college": college,
    "branch": branch,
    "gender": gender,
    "dob": dob,
    "userType": userType,
    "linkedInUrl": linkedInUrl,
    "gitHubUrl": gitHubUrl,
    "twitterUrl": twitterUrl,
    "portfolioUrl": portfolioUrl,
    "latitude": latitude,
    "longitude": longitude,
    "city": city,
    "state": state,
    "country": country,
  };
}
