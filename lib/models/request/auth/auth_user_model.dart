class AuthUserModel {
  final String? id;
  final String? userToken;
  final bool? isFirstTimeUser;

  AuthUserModel({this.id, this.userToken, this.isFirstTimeUser});

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'],
      userToken: json['userToken'],
      isFirstTimeUser: json['isFirstTimeUser'],
    );
  }
}
