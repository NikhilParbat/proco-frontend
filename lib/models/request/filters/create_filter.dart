import 'dart:convert';

class CreateFilterRequest {
  final String agentId;
  final List<String> selectedDomains;
  final List<String> opportunityTypes;
  final String selectedLocationOption;
  final String selectedCity;
  final String selectedState;
  final String selectedCountry;
  final int distanceKm;
  final String postedWithin;
  final List<String> skills;

  CreateFilterRequest({
    required this.agentId,
    this.selectedDomains = const [],
    this.opportunityTypes = const [],
    this.selectedLocationOption = '',
    this.selectedCity = '',
    this.selectedState = '',
    this.selectedCountry = '',
    this.distanceKm = 0,
    this.postedWithin = '',
    this.skills = const [],
  });

  // Convert the Flutter request object directly into a Map payload
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'selectedDomains': selectedDomains,
      'opportunityTypes': opportunityTypes,
      'selectedLocationOption': selectedLocationOption,
      'selectedCity': selectedCity,
      'selectedState': selectedState,
      'selectedCountry': selectedCountry,
      'distanceKm': distanceKm,
      'postedWithin': postedWithin,
      'skills': skills,
    };
  }

  // Helper string serializer to streamline debugging/logging network calls
  String toRawJson() => json.encode(toJson());
}