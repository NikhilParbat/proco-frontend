import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  /// NEW: Structured address lookup for Profile Update
  /// Converts coordinates into separate City, State, and Country strings.
  static Future<({String city, String state, String country})>
  getAddressFromLatLng(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        return (
          city: p.locality ?? "",
          state: p.administrativeArea ?? "",
          country: p.country ?? "",
        );
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
    return (city: "", state: "", country: "");
  }

  /// Requests permission and returns the device's current GPS fix.
  static Future<LocationResult> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission was denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Enable in settings.';
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Optional: only update if user moves 100m
    );

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    String? address;
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        address = [
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
    } catch (_) {}

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      displayAddress: address,
    );
  }

  /// Converts free-text address into coordinates (used for search).
  static Future<LocationResult?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      final List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      final Location loc = locations.first;
      String? displayAddress;
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        if (placemarks.isNotEmpty) {
          final Placemark p = placemarks.first;
          displayAddress = [
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (_) {}

      return LocationResult(
        latitude: loc.latitude,
        longitude: loc.longitude,
        displayAddress: displayAddress ?? address,
      );
    } catch (_) {
      return null;
    }
  }

  // NEW: Provides autocomplete suggestions for location search using Nominatim API.
  static Future<List<Map<String, dynamic>>> getPlacePredictions(
    String query,
  ) async {
    if (query.length < 3) return []; // Don't search for very short strings

    final String url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'proco_app', // Nominatim requires a User-Agent
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'display_name': item['display_name'],
                'lat': double.parse(item['lat']),
                'lon': double.parse(item['lon']),
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint("Autocomplete error: $e");
    }
    return [];
  }
}
