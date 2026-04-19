import 'dart:convert';

/// ======================== LOGIN REQUEST ========================

LoginRequestModel loginRequestModelFromJson(String str) =>
    LoginRequestModel.fromJson(json.decode(str));

String loginRequestModelToJson(LoginRequestModel data) =>
    json.encode(data.toJson());

class LoginRequestModel {
  LoginRequestModel({required this.email, required this.password});

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      LoginRequestModel(email: json['email'], password: json['password']);

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
