class GoogleAuthModel {
  final String idToken;
  final String email;
  final String? displayName;
  final String? photoURL;
  final double? latitude;
  final double? longitude;

  GoogleAuthModel({
    required this.idToken,
    required this.email,
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
