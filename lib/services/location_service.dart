import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result type returned by LocationService methods.
class LocationResult {
  final double latitude;
  final double longitude;
  final String? displayAddress;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.displayAddress,
  });
}

class LocationService {
  // Pull the backend URL from .env
  static String get _baseUrl => dotenv.get('BACKEND_API_URL'); 

  /// REFACTORED: Hits your Node.js /reverse endpoint
  static Future<({String city, String state, String country})>
      getAddressFromLatLng(double lat, double lng) async {
    final String url = '$_baseUrl/api/location/reverse?lat=$lat&lng=$lng';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (
          city: (data['city'] ?? "").toString(),
          state: (data['state'] ?? "").toString(),
          country: (data['country'] ?? "").toString(),
        );
      }
    } catch (e) {
      debugPrint("Backend Reverse Geocoding failed: $e");
    }
    return (city: "", state: "", country: "");
  }

  /// NO CHANGE NEEDED HERE: This handles hardware GPS sensors
  static Future<LocationResult> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Location permission denied.';
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final addressData = await getAddressFromLatLng(position.latitude, position.longitude);
    
    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      displayAddress: "${addressData.city}, ${addressData.state}",
    );
  }

  /// REFACTORED: Hits your Node.js /search endpoint
  static Future<LocationResult?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final String url = '$_baseUrl/api/location/search?q=${Uri.encodeComponent(address)}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);

      return LocationResult(
        latitude: data['latitude'],
        longitude: data['longitude'],
        displayAddress: data['displayAddress'],
      );
    } catch (_) {
      return null;
    }
  }

  /// REFACTORED: Hits your Node.js /autocomplete endpoint
  static Future<List<Map<String, dynamic>>> getPlacePredictions(String query) async {
    if (query.length < 3) return [];

    final String url = '$_baseUrl/api/location/autocomplete?q=${Uri.encodeComponent(query)}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Autocomplete backend error: $e");
    }
    return [];
  }
}