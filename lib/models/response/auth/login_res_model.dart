import 'dart:convert';

/// ======================== LOGIN RESPONSE ========================

LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  LoginResponseModel({
    required this.id,
    required this.username,
    required this.email,
    required this.userToken,
    this.isAdmin,
    this.isAgent,
    required this.isFirstTimeUser,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        userToken: json['userToken'],
        isAdmin: json['isAdmin'],
        isAgent: json['isAgent'],
        isFirstTimeUser: json['isFirstTimeUser'] ?? true,
      );

  final String id;
  final String username;
  final String email;
  final bool? isAdmin;
  final bool? isAgent;
  final bool isFirstTimeUser;
  final String userToken;

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'isAdmin': isAdmin,
    'isAgent': isAgent,
    'isFirstTimeUser': isFirstTimeUser,
    'userToken': userToken,
  };
}
