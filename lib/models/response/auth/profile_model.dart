import 'dart:convert';

ProfileRes profileResFromJson(String str) {
  final decoded = json.decode(str);

  if (decoded['success'] != true) {
    throw Exception(decoded['message'] ?? "Failed to fetch profile");
  }

  return ProfileRes.fromJson(decoded['data'] ?? {});
}

String profileResToJson(ProfileRes data) => json.encode(data.toJson());

class ProfileRes {
  final String id;
  final String username;
  final String email;
  final bool isAdmin;
  final bool isAgent;
  final List<String> skills;
  final DateTime updatedAt;
  final String profile;
  final String phone;
  final String college;
  final String gender;
  final String branch;
  final String dob;
  final String userType;
  final String linkedInUrl;
  final String gitHubUrl;
  final String twitterUrl;
  final String portfolioUrl;
  final bool isFirstTimeUser;

  // ── Parsed from nested location object ──────────────────────────────────
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;

  ProfileRes({
    required this.id,
    required this.username,
    required this.email,
    required this.isAdmin,
    required this.isAgent,
    required this.skills,
    required this.updatedAt,
    required this.profile,
    this.phone = "",
    this.college = "",
    this.gender = "",
    this.branch = "",
    this.dob = "",
    this.userType = "",
    this.linkedInUrl = "",
    this.gitHubUrl = "",
    this.twitterUrl = "",
    this.portfolioUrl = "",
    this.isFirstTimeUser = true,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.city = "",
    this.state = "",
    this.country = "",
  });

  factory ProfileRes.fromJson(Map<String, dynamic> json) {
    // ── Parse nested location object ─────────────────────────────────────
    // MongoDB schema: location: { type, coordinates: [lng, lat], city, state, country }
    double lat = 0.0;
    double lng = 0.0;
    String city = "";
    String state = "";
    String country = "";

    final locationRaw = json['location'];
    if (locationRaw is Map<String, dynamic>) {
      // GeoJSON order is [longitude, latitude]
      final coords = locationRaw['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num?)?.toDouble() ?? 0.0;
        lat = (coords[1] as num?)?.toDouble() ?? 0.0;
      }
      city    = locationRaw['city']    as String? ?? "";
      state   = locationRaw['state']   as String? ?? "";
      country = locationRaw['country'] as String? ?? "";
    }

    return ProfileRes(
      id:       json['_id']      ?? "",
      username: json['username'] ?? "",
      email:    json['email']    ?? "",
      isAdmin:  json['isAdmin']  ?? false,
      isAgent:  json['isAgent']  ?? false,
      skills: json['skills'] != null
          ? List<String>.from(json['skills'])
          : [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      profile: json['profile'] ??
          "https://www.pngplay.com/wp-content/uploads/12/User-Avatar-Profile-Clip-Art-Transparent-PNG.png",
      phone:        json['phone']        ?? "",
      college:      json['college']      ?? "",
      gender:       json['gender']       ?? "",
      branch:       json['branch']       ?? "",
      dob:          json['dob']          ?? "",
      userType:     json['userType']     ?? "",
      linkedInUrl:  json['linkedInUrl']  ?? "",
      gitHubUrl:    json['gitHubUrl']    ?? "",
      twitterUrl:   json['twitterUrl']   ?? "",
      portfolioUrl: json['portfolioUrl'] ?? "",
      isFirstTimeUser: json['isFirstTimeUser'] ?? true,
      latitude:  lat,
      longitude: lng,
      city:    city,
      state:   state,
      country: country,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id':      id,
        'username': username,
        'email':    email,
        'isAdmin':  isAdmin,
        'isAgent':  isAgent,
        'skills':   skills,
        'updatedAt': updatedAt.toIso8601String(),
        'profile':  profile,
        'phone':    phone,
        'college':  college,
        'gender':   gender,
        'branch':   branch,
        'dob':      dob,
        'userType': userType,
        'linkedInUrl':  linkedInUrl,
        'gitHubUrl':    gitHubUrl,
        'twitterUrl':   twitterUrl,
        'portfolioUrl': portfolioUrl,
        'isFirstTimeUser': isFirstTimeUser,
        // Re-serialise nested location so PUT requests stay consistent
        'location': {
          'type': 'Point',
          'coordinates': [longitude, latitude], // GeoJSON: [lng, lat]
          'city':    city,
          'state':   state,
          'country': country,
        },
      };
}