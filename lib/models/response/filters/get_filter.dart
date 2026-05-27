import 'dart:convert';

GetFilterRes getFilterResFromJson(String str) {
  final decoded = json.decode(str);
  final map = (decoded is Map && decoded.containsKey('data'))
      ? decoded['data'] as Map<String, dynamic>
      : decoded as Map<String, dynamic>;
  return GetFilterRes.fromJson(map);
}

String getFilterResToJson(GetFilterRes data) => json.encode(data.toJson());

class GetFilterRes {
  final String id;
  final String agentId;
  final List<String> selectedDomains;
  final List<String> opportunityTypes;
  final String selectedLocationOption;
  final String selectedCity;
  final String selectedState;
  final String selectedCountry;
  final int distanceKm;
  final List<String> skills;
  final bool sortByTime;
  final String postedWithin;

  GetFilterRes({
    required this.id,
    required this.agentId,
    required this.selectedDomains,
    required this.opportunityTypes,
    required this.selectedLocationOption,
    required this.selectedCity,
    required this.selectedState,
    required this.selectedCountry,
    required this.distanceKm,
    required this.skills,
    required this.sortByTime,
    required this.postedWithin,
  });

  factory GetFilterRes.fromJson(Map<String, dynamic> json) => GetFilterRes(
        id: json['id'] ?? '',
        agentId: json['agentId'] ?? '',
        selectedDomains: json['selectedDomains'] != null
            ? List<String>.from(json['selectedDomains'])
            : const [],
        opportunityTypes: json['opportunityTypes'] != null
            ? List<String>.from(json['opportunityTypes'])
            : const [],
        selectedLocationOption: json['selectedLocationOption'] ?? '',
        selectedCity: json['selectedCity'] ?? '',
        selectedState: json['selectedState'] ?? '',
        selectedCountry: json['selectedCountry'] ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toInt() ?? 0,
        skills: json['skills'] != null
            ? List<String>.from(json['skills'])
            : const [],
        sortByTime: json['sortByTime'] == true,
        postedWithin: json['postedWithin'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'agentId': agentId,
        'selectedDomains': List<dynamic>.from(selectedDomains),
        'opportunityTypes': List<dynamic>.from(opportunityTypes),
        'selectedLocationOption': selectedLocationOption,
        'selectedCity': selectedCity,
        'selectedState': selectedState,
        'selectedCountry': selectedCountry,
        'distanceKm': distanceKm,
        'skills': List<dynamic>.from(skills),
        'sortByTime': sortByTime,
        'postedWithin': postedWithin,
      };
}