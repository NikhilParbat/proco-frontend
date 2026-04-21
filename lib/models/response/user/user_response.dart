class UserResponse {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? profile;
  final String? college;
  final String? branch;
  final String? gender;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String linkedInUrl;
  final String gitHubUrl;
  final String twitterUrl;
  final String portfolioUrl;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.profile,
    this.college,
    this.branch,
    this.gender,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.linkedInUrl = "",
    this.gitHubUrl = "",
    this.twitterUrl = "",
    this.portfolioUrl = "",
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      profile: json['profile'],
      college: json['college'],
      branch: json['branch'],
      gender: json['gender'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      linkedInUrl: json['linkedInUrl'] ?? "",
      gitHubUrl: json['gitHubUrl'] ?? "",
      twitterUrl: json['twitterUrl'] ?? "",
      portfolioUrl: json['portfolioUrl'] ?? "",
    );
  }
}
