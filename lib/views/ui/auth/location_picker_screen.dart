import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:proco/services/location_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const LocationPickerScreen({super.key, required this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _markerVisible = true;
  bool _isLoading = false;
  bool _isGeocoding = false;
  String _displayAddress = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _updateAddress(_selectedPosition.latitude, _selectedPosition.longitude);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(double lat, double lng) async {
    setState(() => _isGeocoding = true);
    try {
      final addressData = await LocationService.getAddressFromLatLng(lat, lng);
      if (mounted) {
        setState(() {
          _displayAddress = "${addressData.city}, ${addressData.state}";
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _moveMap(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 13.0);
    setState(() {
      _selectedPosition = LatLng(lat, lng);
      _markerVisible = true;
    });
    _updateAddress(lat, lng);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _searchResults = []);
        return;
      }

      setState(() => _isLoading = true);
      try {
        final results = await LocationService.getPlacePredictions(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Stack(
        children: [
          // 1. The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 13.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedPosition = latLng;
                  _markerVisible = true;
                  _searchResults = [];
                  _searchController.clear();
                });
                _updateAddress(latLng.latitude, latLng.longitude);
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
                      point: _selectedPosition,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF08979F),
                        size: 48,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Overlay: Search and GPS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back Button Row
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(
                          0xFF040326,
                        ).withOpacity(0.8),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF040326).withOpacity(0.92),
                      borderRadius: _searchResults.isEmpty
                          ? BorderRadius.circular(12)
                          : const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                      border: Border.all(
                        color: const Color(0xFF08979F).withOpacity(0.6),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search location…',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF08979F),
                        ),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF08979F),
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  // ── Suggestions List Overlay ───────────────────────────────────────
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200.h,
                      ), // Limit height
                      decoration: BoxDecoration(
                        color: const Color(0xFF040326).withOpacity(0.95),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        border: Border.all(
                          color: const Color(0xFF08979F).withOpacity(0.4),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF08979F),
                              size: 18,
                            ),
                            title: Text(
                              item['display_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              // When user taps a suggestion, move map there
                              _moveMap(item['lat'], item['lon']);
                              setState(() => _searchResults = []); // Close list
                              _searchController.text = item['display_name'];
                              FocusScope.of(
                                context,
                              ).unfocus(); // Close keyboard
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  // "Use Current Location" button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF08979F,
                        ).withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.my_location, size: 20),
                      label: const Text('Use Current Location'),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final result =
                                    await LocationService.getCurrentLocation();
                                _moveMap(result.latitude, result.longitude);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Confirm Button
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Address Card ──
                if (_displayAddress.isNotEmpty || _isGeocoding)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040326).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF08979F).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isGeocoding)
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF08979F),
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            _isGeocoding
                                ? "Fetching address..."
                                : _displayAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Confirm Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08979F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isGeocoding
                        ? null
                        : () => Navigator.pop(context, _selectedPosition),
                    child: const Text(
                      "Confirm This Location",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
