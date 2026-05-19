import 'dart:convert';

List<FilterResponse> filterResponseFromJson(String str) {
  final decoded = json.decode(str);
  final list = (decoded is Map && decoded.containsKey('data'))
      ? decoded['data'] as List
      : decoded as List;
  return list
      .map((e) => FilterResponse.fromJson(e as Map<String, dynamic>))
      .toList();
}

class FilterResponse {
  final String id;
  final String? agentId;
  final List<String> selectedDomains;
  final List<String> opportunityTypes;
  final String? selectedLocationOption;
  final String? selectedCity;
  final String? selectedState;
  final String? selectedCountry;
  final int distanceKm;
  final bool? sortByTime;
  final String? postedWithin;
  final List<String> skills;
  final DateTime? updatedAt;

  FilterResponse({
    required this.id,
    this.agentId,
    this.selectedDomains = const [],
    this.opportunityTypes = const [],
    this.selectedLocationOption,
    this.selectedCity,
    this.selectedState,
    this.selectedCountry,
    this.distanceKm = 0,
    this.sortByTime,
    this.postedWithin,
    this.skills = const [],
    this.updatedAt,
  });

  factory FilterResponse.fromJson(Map<String, dynamic> json) => FilterResponse(
        id: json['id'] ?? '',
        agentId: json['agentId'],
        selectedDomains: json['selectedDomains'] != null
            ? List<String>.from(json['selectedDomains'])
            : const [],
        opportunityTypes: json['opportunityTypes'] != null
            ? List<String>.from(json['opportunityTypes'])
            : const [],
        selectedLocationOption: json['selectedLocationOption'],
        selectedCity: json['selectedCity'],
        selectedState: json['selectedState'],
        selectedCountry: json['selectedCountry'],
        distanceKm: (json['distanceKm'] as num?)?.toInt() ?? 0,
        sortByTime: json['sortByTime'] as bool?,
        postedWithin: json['postedWithin'],
        skills: json['skills'] != null
            ? List<String>.from(json['skills'])
            : const [],
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );
}