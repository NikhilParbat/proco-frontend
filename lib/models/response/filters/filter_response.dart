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
  FilterResponse({
    required this.id,
    this.agentId,
    this.selectedLocationOption,
    this.selectedCity,
    this.selectedState,
    this.selectedCountry,
    this.sortByTime,
    this.postedWithin,
    this.internship,
    this.research,
    this.freelance,
    this.competition,
    this.updatedAt,
  });

  factory FilterResponse.fromJson(Map<String, dynamic> json) => FilterResponse(
        id: json['id'] ?? '',
        agentId: json['agentId'],
        selectedLocationOption: json['selectedLocationOption'],
        selectedCity: json['selectedCity'],
        selectedState: json['selectedState'],
        selectedCountry: json['selectedCountry'],
        sortByTime: json['sortByTime'] as bool?,
        postedWithin: json['postedWithin'],
        internship: json['internship'] as bool?,
        research: json['research'] as bool?,
        freelance: json['freelance'] as bool?,
        competition: json['competition'] as bool?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );

  final String id;
  final String? agentId;
  final String? selectedLocationOption;
  final String? selectedCity;
  final String? selectedState;
  final String? selectedCountry;
  final bool? sortByTime;
  final String? postedWithin;
  final bool? internship;
  final bool? research;
  final bool? freelance;
  final bool? competition;
  final DateTime? updatedAt;
}
