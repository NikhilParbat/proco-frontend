import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/services/location_service.dart';
import 'package:provider/provider.dart';

class ObLocationPage extends StatefulWidget {
  const ObLocationPage({super.key});

  @override
  State<ObLocationPage> createState() => _ObLocationPageState();
}

class _ObLocationPageState extends State<ObLocationPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _markerPosition = const LatLng(20.5937, 78.9629);
  bool _markerVisible = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _locationLoading = false;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _moveMap(double lat, double lng) {
    final target = LatLng(lat, lng);
    setState(() {
      _markerPosition = target;
      _markerVisible = true;
      _searchResults = [];
    });
    _mapController.move(target, 13.0);
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'proco_app'},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            final addr = item['address'] as Map<String, dynamic>? ?? {};
            return {
              'display_name': item['display_name'],
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
              'city': addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '',
              'state': addr['state'] ?? '',
              'country': addr['country'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'proco_app'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        return {
          'display': data['display_name'] as String? ?? '',
          'city': addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '',
          'state': addr['state'] ?? '',
          'country': addr['country'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return {'display': '', 'city': '', 'state': '', 'country': ''};
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markerPosition,
              initialZoom: 5.0,
              onTap: (_, latLng) async {
                _moveMap(latLng.latitude, latLng.longitude);
                _searchController.clear();
                FocusScope.of(context).unfocus();
                final geo = await _reverseGeocode(latLng.latitude, latLng.longitude);
                provider.setLocation(
                  latLng.latitude,
                  latLng.longitude,
                  displayAddress: geo['display'] ?? '',
                  city: geo['city'] ?? '',
                  state: geo['state'] ?? '',
                  country: geo['country'] ?? '',
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.proco.proco',
              ),
              MarkerLayer(
                markers: [
                  if (_markerVisible)
                    Marker(
                      point: _markerPosition,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: kTeal,
                        size: 48,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Skip button ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => provider.nextPage(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF040326).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),

          // ── Top overlay: search + GPS ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search title
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Where are you based?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF040326).withValues(alpha: 0.92),
                      borderRadius: _searchResults.isEmpty
                          ? BorderRadius.circular(12)
                          : const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(
                        color: kTeal.withValues(alpha: 0.6),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search location…',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: kTeal),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kTeal,
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults = []);
                                    },
                                  )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  // Search results dropdown
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040326).withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        border: Border.all(color: kTeal.withValues(alpha: 0.4)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: kTeal, size: 18),
                            title: Text(
                              item['display_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            onTap: () {
                              final lat = item['lat'] as double;
                              final lon = item['lon'] as double;
                              _moveMap(lat, lon);
                              _searchController.text = item['display_name'];
                              FocusScope.of(context).unfocus();
                              provider.setLocation(
                                lat,
                                lon,
                                displayAddress: item['display_name'],
                                city: item['city'] ?? '',
                                state: item['state'] ?? '',
                                country: item['country'] ?? '',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Use current location button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal.withValues(alpha: 0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _locationLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: const Text('Use Current Location'),
                      onPressed: _locationLoading
                          ? null
                          : () async {
                              setState(() => _locationLoading = true);
                              try {
                                final result = await LocationService.getCurrentLocation();
                                _moveMap(result.latitude, result.longitude);
                                final geo = await _reverseGeocode(result.latitude, result.longitude);
                                provider.setLocation(
                                  result.latitude,
                                  result.longitude,
                                  displayAddress: geo['display'] ?? result.displayAddress ?? '',
                                  city: geo['city'] ?? '',
                                  state: geo['state'] ?? '',
                                  country: geo['country'] ?? '',
                                );
                              } catch (e) {
                                Get.snackbar('Location Error', e.toString(),
                                    backgroundColor: kOrange, colorText: kLight);
                              } finally {
                                setState(() => _locationLoading = false);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom overlay: selected address + confirm ────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Consumer<OnboardingFlowProvider>(
              builder: (context, prov, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prov.hasLocation && prov.displayAddress.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040326).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kTeal.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        prov.displayAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTeal,
                        disabledBackgroundColor: kTeal.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: prov.hasLocation ? () => prov.nextPage() : null,
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
