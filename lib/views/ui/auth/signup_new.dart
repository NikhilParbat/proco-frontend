import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/signup_provider.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:proco/views/common/custom_textfield_input.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController collegeController = TextEditingController();
  final TextEditingController branchController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController locationSearchController =
      TextEditingController();

  // ── Map state ────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();

  /// Starting camera position (world center – will move on first location pick).
  LatLng _markerPosition = const LatLng(20.5937, 78.9629); // India centre
  bool _markerVisible = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  final List<String> genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    collegeController.dispose();
    branchController.dispose();
    genderController.dispose();
    locationSearchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _moveMap(double lat, double lng) {
    final target = LatLng(lat, lng);
    setState(() {
      _markerPosition = target;
      _markerVisible = true;
    });
    _mapController.move(target, 13.0);
  }

  /// Fetches suggestions directly from Nominatim API
  Future<void> _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Using Nominatim API (Free, requires User-Agent)
      final url =
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'proco_app', // Nominatim requires a User-Agent
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data
              .map(
                (item) => {
                  'display_name': item['display_name'],
                  'lat': double.parse(item['lat']),
                  'lon': double.parse(item['lon']),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Autocomplete error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpNotifier(),
      child: Consumer<SignUpNotifier>(
        builder: (context, signUpProvider, child) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(0.065.sh),
              child: CustomAppBar(
                text: 'Sign Up',
                child: GestureDetector(
                  onTap: () {
                    if (signUpProvider.activeIndex > 0) {
                      signUpProvider.changeStep(signUpProvider.activeIndex - 1);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF08979F),
                    size: 20,
                  ),
                ),
              ),
            ),
            body: IndexedStack(
              index: signUpProvider.activeIndex,
              children: [
                _namePage(signUpProvider),
                _emailPage(signUpProvider),
                _passwordPage(signUpProvider),
                _collegePage(signUpProvider),
                _genderPage(signUpProvider),
                _locationPage(signUpProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Step pages (1-5 unchanged, 6 replaced)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Step 1: Full Name
  Widget _namePage(SignUpNotifier signUpProvider) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("What should other\nProfessionals call you?"),
            const SizedBox(height: 15),
            CustomTextFieldInput(
              controller: nameController,
              hintText: 'Full Name',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            _nextButton(
              onTap: () {
                if (nameController.text.isEmpty) {
                  _snack('Invalid Name', 'Name cannot be empty.');
                  return;
                }
                signUpProvider.signupModel.username = nameController.text;
                signUpProvider.changeStep(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Step 2: Email
  Widget _emailPage(SignUpNotifier signUpProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("What's your email?"),
            const SizedBox(height: 15),
            CustomTextFieldInput(
              controller: emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _nextButton(
              onTap: () {
                if (emailController.text.isEmpty) {
                  _snack('Invalid Email', 'Email cannot be empty.');
                  return;
                }
                signUpProvider.signupModel.email = emailController.text;
                signUpProvider.changeStep(2);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Step 3: Password
  Widget _passwordPage(SignUpNotifier signUpProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("Create a secure password"),
            const SizedBox(height: 15),
            CustomTextFieldInput(
              controller: passwordController,
              hintText: 'Password',
              keyboardType: TextInputType.text,
              obscureText: signUpProvider.obscureText,
              validator: (password) {
                if (!signUpProvider.passwordValidator(password!)) {
                  return 'At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special character.';
                }
                return null;
              },
              suffixIcon: GestureDetector(
                onTap: () =>
                    signUpProvider.obscureText = !signUpProvider.obscureText,
                child: Icon(
                  signUpProvider.obscureText
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _nextButton(
              onTap: () {
                if (!signUpProvider.passwordValidator(
                  passwordController.text,
                )) {
                  _snack(
                    'Invalid Password',
                    'Password must have uppercase, lowercase, digit & special character.',
                  );
                } else {
                  signUpProvider.signupModel.password = passwordController.text;
                  signUpProvider.changeStep(3);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Step 4: College & Branch
  Widget _collegePage(SignUpNotifier signUpProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("Which College do you belong to?"),
            const SizedBox(height: 15),
            CustomTextFieldInput(
              controller: collegeController,
              hintText: 'College',
              keyboardType: TextInputType.text,
            ),
            CustomTextFieldInput(
              controller: branchController,
              hintText: 'Branch',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            _nextButton(
              onTap: () {
                if (collegeController.text.isEmpty) {
                  _snack('Invalid College', 'College cannot be empty.');
                  return;
                }
                if (branchController.text.isEmpty) {
                  _snack('Invalid Branch', 'Branch cannot be empty.');
                  return;
                }
                signUpProvider.signupModel.college = collegeController.text;
                signUpProvider.signupModel.branch = branchController.text;
                signUpProvider.changeStep(4);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Step 5: Gender
  Widget _genderPage(SignUpNotifier signUpProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("Please specify your Gender"),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: genderController.text.isEmpty
                  ? null
                  : genderController.text,
              dropdownColor: kLightBlue,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Select Gender',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: genderOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => genderController.text = newValue!),
            ),
            const SizedBox(height: 20),
            _nextButton(
              onTap: () {
                if (genderController.text.isEmpty) {
                  _snack('Invalid Gender', 'Gender cannot be empty.');
                  return;
                }
                signUpProvider.signupModel.gender = genderController.text;
                signUpProvider.changeStep(5);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Step 6 — Interactive Map Location Page (UPDATED for flutter_map v8)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _locationPage(SignUpNotifier signUpProvider) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // flutter_map v8 uses initialCenter + initialZoom
              initialCenter: _markerPosition,
              initialZoom: 5.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _markerPosition = latLng;
                  _markerVisible = true;
                  _searchResults = [];
                  locationSearchController.clear();
                });
                signUpProvider.setLocation(latLng.latitude, latLng.longitude);
                FocusScope.of(context).unfocus(); // Dismiss keyboard if open
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
                        color: Color(0xFF08979F),
                        size: 48,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // ── Top overlay: search bar + GPS button ─────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF040326).withValues(alpha: 0.92),
                      borderRadius: _searchResults.isEmpty
                          ? BorderRadius.circular(12)
                          : const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                      border: Border.all(
                        color: const Color(0xFF08979F).withValues(alpha: 0.6),
                      ),
                    ),
                    child: TextField(
                      controller: locationSearchController,
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
                        suffixIcon: _isSearching
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
                            : locationSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    locationSearchController.clear(),
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
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 250.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040326).withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        border: Border.all(
                          color: const Color(0xFF08979F).withValues(alpha: 0.4),
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
                              _moveMap(item['lat'], item['lon']);
                              signUpProvider.setLocation(
                                item['lat'],
                                item['lon'],
                              );
                              locationSearchController.text =
                                  item['display_name'];
                              setState(() => _searchResults = []);
                              FocusScope.of(context).unfocus();
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
                        ).withValues(alpha: 0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.my_location, size: 20),
                      label: const Text('Use Current Location'),
                      onPressed: signUpProvider.locationLoading
                          ? null
                          : () async {
                              final result = await signUpProvider
                                  .fetchCurrentLocation();
                              if (result != null) {
                                _moveMap(result.latitude, result.longitude);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom overlay: coordinate chip + confirm button ─────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show selected address
                if (signUpProvider.hasLocation)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040326).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF08979F).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (signUpProvider.displayAddress.isNotEmpty)
                          Text(
                            signUpProvider.displayAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08979F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF08979F,
                      ).withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: signUpProvider.hasLocation
                        ? () => signUpProvider.submitSignup()
                        : null,
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Shared UI helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08979F), Color(0xFF040326)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _cardTitle(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 26.sp,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );

  Widget _nextButton({required VoidCallback onTap}) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipOval(
            child: Image.asset(
              'assets/images/Sign_in_circle.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: kLightBlue,
      colorText: Colors.white,
    );
  }
}
