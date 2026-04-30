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
  GetFilterRes({
    required this.id,
    required this.selectedOptions,
    required this.selectedLocationOption,
    required this.selectedCity,
    required this.selectedState,
    required this.selectedCountry,
    required this.customOptions,
    required this.skills,
    required this.sortByTime,
    required this.postedWithin,
    required this.internship,
    required this.research,
    required this.freelance,
    required this.competition,
    required this.collaborate,
  });

  factory GetFilterRes.fromJson(Map<String, dynamic> json) => GetFilterRes(
        id: json['id'] ?? '',
        selectedOptions: json['selectedOptions'] != null
            ? List<String>.from(json['selectedOptions'])
            : [],
        selectedLocationOption: json['selectedLocationOption'] ?? '',
        selectedCity: json['selectedCity'] ?? '',
        selectedState: json['selectedState'] ?? '',
        selectedCountry: json['selectedCountry'] ?? '',
        customOptions: json['customOptions'] != null
            ? List<String>.from(json['customOptions'])
            : [],
        skills: json['skills'] != null
            ? List<String>.from(json['skills'])
            : [],
        sortByTime: json['sortByTime'] == true,
        postedWithin: json['postedWithin'] as String? ?? '',
        internship: json['internship'] == true,
        research: json['research'] == true,
        freelance: json['freelance'] == true,
        competition: json['competition'] == true,
        collaborate: json['collaborate'] == true,
      );

  final String id;
  final List<String> selectedOptions;
  final String selectedLocationOption;
  final String selectedCity;
  final String selectedState;
  final String selectedCountry;
  final List<String> customOptions;
  final List<String> skills;
  final bool sortByTime;
  final String postedWithin;
  final bool internship;
  final bool research;
  final bool freelance;
  final bool competition;
  final bool collaborate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'selectedOptions': List<dynamic>.from(selectedOptions),
        'selectedLocationOption': selectedLocationOption,
        'selectedCity': selectedCity,
        'selectedState': selectedState,
        'selectedCountry': selectedCountry,
        'customOptions': List<dynamic>.from(customOptions),
        'skills': List<dynamic>.from(skills),
        'sortByTime': sortByTime,
        'postedWithin': postedWithin,
        'internship': internship,
        'research': research,
        'freelance': freelance,
        'competition': competition,
        'collaborate': collaborate,
      };
}
