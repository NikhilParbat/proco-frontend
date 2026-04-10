// models/request/auth/google_auth_model.dart
class GoogleAuthModel {
  String? idToken;
  String? email;
  String? displayName;
  String? photoURL;
  double? latitude;
  double? longitude;

  GoogleAuthModel({
    this.idToken,
    this.email,
    this.displayName,
    this.photoURL,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'idToken': idToken,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
