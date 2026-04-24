class ProfileUpdateReq {
  final String username;
  final String city;
  final String state;
  final String country;
  final String phone;
  final String college;
  final String branch;
  final String? gender;
  final String dob;
  final String userType;
  final String linkedInUrl;
  final String gitHubUrl;
  final String twitterUrl;
  final String portfolioUrl;
  final double latitude;
  final double longitude;
  final List<String> skills;
  final List<String> interests; // NEW
  final List<String> hobbies; // NEW

  ProfileUpdateReq({
    required this.username,
    this.city = '',
    this.state = '',
    this.country = '',
    this.phone = '',
    this.college = '',
    this.branch = '',
    this.gender,
    this.dob = '',
    this.userType = '',
    this.linkedInUrl = '',
    this.gitHubUrl = '',
    this.twitterUrl = '',
    this.portfolioUrl = '',
    this.latitude = 0,
    this.longitude = 0,
    this.skills = const [],
    this.interests = const [], // NEW
    this.hobbies = const [], // NEW
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'city': city,
      'state': state,
      'country': country,
      'phone': phone,
      'college': college,
      'branch': branch,
      'gender': gender,
      'dob': dob,
      'userType': userType,
      'linkedInUrl': linkedInUrl,
      'gitHubUrl': gitHubUrl,
      'twitterUrl': twitterUrl,
      'portfolioUrl': portfolioUrl,
      'latitude': latitude,
      'longitude': longitude,
      'skills': skills,
      'interests': interests, // NEW
      'hobbies': hobbies, // NEW
    };
  }

  ProfileUpdateReq copyWith({
    String? username,
    String? city,
    String? state,
    String? country,
    String? phone,
    String? college,
    String? branch,
    String? gender,
    String? dob,
    String? userType,
    String? linkedInUrl,
    String? gitHubUrl,
    String? twitterUrl,
    String? portfolioUrl,
    double? latitude,
    double? longitude,
    List<String>? skills,
    List<String>? interests, // NEW
    List<String>? hobbies, // NEW
  }) {
    return ProfileUpdateReq(
      username: username ?? this.username,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      college: college ?? this.college,
      branch: branch ?? this.branch,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      userType: userType ?? this.userType,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      gitHubUrl: gitHubUrl ?? this.gitHubUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests, // NEW
      hobbies: hobbies ?? this.hobbies, // NEW
    );
  }
}
