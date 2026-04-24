class UserResponse {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final bool? isAdmin;
  final bool? isAgent;
  final String? profile;
  final String? college;
  final String? gender;
  final String? branch;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? dob;
  final String? linkedInUrl;
  final String? gitHubUrl;
  final String? twitterUrl;
  final String? portfolioUrl;
  final String? userType;
  final String? provider;
  final bool? isFirstTimeUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> skills; // NEW
  final List<String> interests; // NEW
  final List<String> hobbies; // NEW

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.isAdmin,
    this.isAgent,
    this.profile,
    this.college,
    this.gender,
    this.branch,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.dob,
    this.linkedInUrl,
    this.gitHubUrl,
    this.twitterUrl,
    this.portfolioUrl,
    this.userType,
    this.provider,
    this.isFirstTimeUser,
    this.createdAt,
    this.updatedAt,
    this.skills = const [], // NEW
    this.interests = const [], // NEW
    this.hobbies = const [], // NEW
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      isAdmin: json['isAdmin'],
      isAgent: json['isAgent'],
      profile: json['profile'],
      college: json['college'],
      gender: json['gender'],
      branch: json['branch'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      dob: json['dob'],
      linkedInUrl: json['linkedInUrl'],
      gitHubUrl: json['gitHubUrl'],
      twitterUrl: json['twitterUrl'],
      portfolioUrl: json['portfolioUrl'],
      userType: json['userType'],
      provider: json['provider'],
      isFirstTimeUser: json['isFirstTimeUser'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      // NEW: Parse arrays
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      hobbies: json['hobbies'] != null
          ? List<String>.from(json['hobbies'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'isAdmin': isAdmin,
      'isAgent': isAgent,
      'profile': profile,
      'college': college,
      'gender': gender,
      'branch': branch,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'dob': dob,
      'linkedInUrl': linkedInUrl,
      'gitHubUrl': gitHubUrl,
      'twitterUrl': twitterUrl,
      'portfolioUrl': portfolioUrl,
      'userType': userType,
      'provider': provider,
      'isFirstTimeUser': isFirstTimeUser,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'skills': skills, // NEW
      'interests': interests, // NEW
      'hobbies': hobbies, // NEW
    };
  }

  UserResponse copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    bool? isAdmin,
    bool? isAgent,
    String? profile,
    String? college,
    String? gender,
    String? branch,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
    String? dob,
    String? linkedInUrl,
    String? gitHubUrl,
    String? twitterUrl,
    String? portfolioUrl,
    String? userType,
    String? provider,
    bool? isFirstTimeUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? skills, // NEW
    List<String>? interests, // NEW
    List<String>? hobbies, // NEW
  }) {
    return UserResponse(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isAdmin: isAdmin ?? this.isAdmin,
      isAgent: isAgent ?? this.isAgent,
      profile: profile ?? this.profile,
      college: college ?? this.college,
      gender: gender ?? this.gender,
      branch: branch ?? this.branch,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      gitHubUrl: gitHubUrl ?? this.gitHubUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      userType: userType ?? this.userType,
      provider: provider ?? this.provider,
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skills: skills ?? this.skills, // NEW
      interests: interests ?? this.interests, // NEW
      hobbies: hobbies ?? this.hobbies, // NEW
    );
  }
}
