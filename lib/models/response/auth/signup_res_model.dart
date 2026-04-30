class SignupResponseModel {
  final String userId;

  SignupResponseModel({required this.userId});

  factory SignupResponseModel.fromJson(dynamic data) {
    return SignupResponseModel(userId: data);
  }
}
