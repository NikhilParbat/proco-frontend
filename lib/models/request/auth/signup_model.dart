import 'dart:convert';

SignupModel signupModelFromJson(String str) =>
    SignupModel.fromJson(json.decode(str));

String signupModelToJson(SignupModel data) => json.encode(data.toJson());

class SignupModel {
  SignupModel({
    this.username = '',
    this.email = '',
    this.password = '',
    this.college = '',
    this.branch = '',
    this.gender = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  String username;
  String email;
  String password;
  String college;
  String branch;
  String gender;
  double latitude;
  double longitude;

  factory SignupModel.fromJson(Map<String, dynamic> json) => SignupModel(
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        college: json['college'] ?? '',
        branch: json['branch'] ?? '',
        gender: json['gender'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'college': college,
        'branch': branch,
        'gender': gender,
        'latitude': latitude,   // sent as number
        'longitude': longitude, // sent as number
      };
}