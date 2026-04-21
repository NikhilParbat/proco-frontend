import 'dart:convert';

String createFilterRequestToJson(CreateFilterRequest data) => json.encode(data.toJson());

class CreateFilterRequest {
  CreateFilterRequest({
    required this.agentId,
    this.selectedOptions,
    this.selectedLocationOption,
    this.selectedCity,
    this.selectedState,
    this.selectedCountry,
    this.customOptions,
    this.skills,
    this.sortByTime,
    this.postedWithin,
    this.internship,
    this.research,
    this.freelance,
    this.competition,
    this.collaborate,
  });

  final String agentId;
  final List<String>? selectedOptions;
  final String? selectedLocationOption;
  final String? selectedCity;
  final String? selectedState;
  final String? selectedCountry;
  final List<String>? customOptions;
  final List<String>? skills;
  final bool? sortByTime;
  final String? postedWithin;
  final bool? internship;
  final bool? research;
  final bool? freelance;
  final bool? competition;
  final bool? collaborate;

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'selectedOptions': selectedOptions ?? [],
        'selectedLocationOption': selectedLocationOption,
        'selectedCity': selectedCity,
        'selectedState': selectedState,
        'selectedCountry': selectedCountry,
        'customOptions': customOptions ?? [],
        'skills': skills ?? [],
        'sortByTime': sortByTime,
        'postedWithin': postedWithin,
        'internship': internship,
        'research': research,
        'freelance': freelance,
        'competition': competition,
        'collaborate': collaborate,
      };
}
