import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proco/controllers/image_provider.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:proco/views/ui/auth/location_picker_screen.dart';
import 'package:proco/services/location_service.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  // ─── Theme colors ────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF040326);
  static const Color _card = Color(0xFF08979F);
  static const Color _accent = Color(0xFF0BBFCA);
  static const Color _white = Colors.white;

  // ─── Form ─────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _skillController = TextEditingController();
  final _interestController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _dobController = TextEditingController();

  double _latitude = 0.0;
  double _longitude = 0.0;

  String? _selectedGender;
  static const List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  String? _selectedUserType;
  static const List<String> _userTypeOptions = [
    'Student',
    'Young Professional',
  ];

  List<String> skills = [];
  List<String> interests = [];
  List<String> hobbies = [];
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _userController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _skillController.dispose();
    _interestController.dispose();
    _hobbyController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _addInterest() {
    final val = _interestController.text.trim();
    if (val.isEmpty || interests.contains(val)) return;

    setState(() {
      interests.add(val);
      _interestController.clear();
    });
  }

  void _addHobby() {
    final val = _hobbyController.text.trim();
    if (val.isEmpty || hobbies.contains(val)) return;

    setState(() {
      hobbies.add(val);
      _hobbyController.clear();
    });
  }

  // ─── Data ─────────────────────────────────────────────────────────────────
  void _loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await UserHelper.getProfile();

      if (!response.success) {
        setState(() => errorMessage = response.message);
        return;
      }

      final profileData = response.data;

      if (profileData != null) {
        setState(() {
          _userController.text = profileData.username;
          _phoneController.text = profileData.phone ?? '';
          _cityController.text = profileData.city ?? '';
          _stateController.text = profileData.state ?? '';
          _countryController.text = profileData.country ?? '';
          _collegeController.text = profileData.college ?? '';
          _branchController.text = profileData.branch ?? '';
          _dobController.text = profileData.dob ?? '';
          skills = profileData.skills;
          interests = profileData.interests;
          hobbies = profileData.hobbies;

          final g = profileData.gender;
          _selectedGender = _genderOptions.contains(g) ? g : null;

          final ut = profileData.userType;
          _selectedUserType = _userTypeOptions.contains(ut) ? ut : null;
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Error loading profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      _snack(
        'Validation Error',
        'Please fill in all required fields',
        Colors.red,
      );
      return;
    }

    setState(() {
      isUpdating = true;
      errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      if (!_isValidPhone(phone)) {
        throw Exception('Please enter a valid phone number');
      }

      // ✅ Get the uploaded selectedImage from ImageNotifier if available
      final imageNotifier = context.read<ImageNotifier>();

      final updateReq = ProfileUpdateReq(
        username: _userController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        phone: phone,
        skills: skills,
        college: _collegeController.text.trim(),
        branch: _branchController.text.trim(),
        gender: _selectedGender,
        dob: _dobController.text.trim(),
        userType: _selectedUserType ?? '',
        interests: interests,
        hobbies: hobbies,
        latitude: _latitude,
        longitude: _longitude,
      );

      final response = await UserHelper.updateProfile(
        updateReq,
        imageNotifier.selectedImage,
      );

      if (response.success) {
        _snack('Success', response.message, Colors.green);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Get.offAll(() => const MainScreen());
      } else {
        setState(() => errorMessage = response.message);
        _snack('Update Failed', response.message, Colors.orange);
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: ${e.toString()}');
      _snack('Error', e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  bool _isValidPhone(String phone) =>
      phone.length >= 10 && RegExp(r'^\d{10,15}$').hasMatch(phone);

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) return;
    if (skills.contains(skill)) {
      _snack('Duplicate', 'This skill is already in your list', Colors.orange);
      return;
    }
    setState(() {
      skills.add(skill);
      _skillController.clear();
    });
  }

  Widget _tagInput(
    TextEditingController controller,
    VoidCallback onAdd,
    String label,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            onFieldSubmitted: (_) => onAdd(),
            decoration: InputDecoration(labelText: label),
          ),
        ),
        IconButton(onPressed: onAdd, icon: Icon(Icons.add)),
      ],
    );
  }

  Widget _tagChips(List<String> list, Function(String) onRemove) {
    if (list.isEmpty) {
      return Text("No items");
    }

    return Wrap(
      children: list.map((item) {
        return Chip(label: Text(item), onDeleted: () => onRemove(item));
      }).toList(),
    );
  }

  void _snack(String title, String msg, Color color) {
    Get.snackbar(
      title,
      msg,
      colorText: _white,
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageNotifier(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _white,
              size: 20,
            ),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _white),
              onPressed: isLoading ? null : _loadProfile,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : (errorMessage != null && errorMessage!.contains('Could not load'))
            ? _buildErrorView()
            : _buildForm(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          _primaryButton('Try Again', _loadProfile),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Picture ───────────────────────────────────────────
            _buildImagePicker(),
            SizedBox(height: 24.h),

            // ── Personal Info ─────────────────────────────────────────────
            _sectionLabel('Personal Info'),
            SizedBox(height: 12.h),
            _field(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '10-digit number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              required: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!_isValidPhone(v)) return 'Enter a valid phone number';
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _genderDropdown(),
            SizedBox(height: 12.h),
            _userTypeDropdown(),
            SizedBox(height: 12.h),
            _dobPicker(),
            SizedBox(height: 20.h),

            // ── Location ──────────────────────────────────────────────────
            _sectionLabel('Location'),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(
                      initialPosition: LatLng(_latitude, _longitude),
                    ),
                  ),
                );

                if (result != null) {
                  final address = await LocationService.getAddressFromLatLng(
                    result.latitude,
                    result.longitude,
                  );
                  setState(() {
                    _latitude = result.latitude;
                    _longitude = result.longitude;
                    _cityController.text = address.city;
                    _stateController.text = address.state;
                    _countryController.text = address.country;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(14.h),
                decoration: BoxDecoration(
                  color: _card.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, color: _accent),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Update via Map",
                            style: TextStyle(
                              color: _accent,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}",
                            style: TextStyle(color: _white, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_location_alt_outlined,
                      color: _accent,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _field(
              controller: _cityController,
              label: 'City',
              icon: Icons.location_city_outlined,
              required: true,
              readOnly: true,
            ),
            SizedBox(height: 12.h),
            _field(
              controller: _stateController,
              label: 'State',
              icon: Icons.map_outlined,
              required: true,
              readOnly: true,
            ),
            SizedBox(height: 12.h),
            _field(
              controller: _countryController,
              label: 'Country',
              icon: Icons.flag_outlined,
              required: true,
              readOnly: true,
            ),
            SizedBox(height: 20.h),

            // ── Education ─────────────────────────────────────────────────
            _sectionLabel('Education'),
            SizedBox(height: 12.h),
            _field(
              controller: _collegeController,
              label: 'College / University',
              hint: 'Enter your institution name',
              icon: Icons.apartment_outlined,
            ),
            SizedBox(height: 12.h),
            _field(
              controller: _branchController,
              label: 'Branch / Field of Study',
              hint: 'e.g. Computer Science',
              icon: Icons.school_outlined,
            ),
            SizedBox(height: 20.h),

            // Skills
            _sectionLabel('Skills'),
            _tagInput(_skillController, _addSkill, "Add skill"),
            _tagChips(skills, (val) => setState(() => skills.remove(val))),

            // Interests
            _sectionLabel('Interests'),
            _tagInput(_interestController, _addInterest, "Add interest"),
            _tagChips(
              interests,
              (val) => setState(() => interests.remove(val)),
            ),

            // Hobbies
            _sectionLabel('Hobbies'),
            _tagInput(_hobbyController, _addHobby, "Add hobby"),
            _tagChips(hobbies, (val) => setState(() => hobbies.remove(val))),

            // ── Submit ────────────────────────────────────────────────────
            _primaryButton(
              isUpdating ? 'Updating...' : 'Save Changes',
              isUpdating ? null : _updateProfile,
              loading: isUpdating,
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  // ─── Image Picker Widget ──────────────────────────────────────────────────
  Widget _buildImagePicker() {
    return Consumer<ImageNotifier>(
      builder: (context, imageNotifier, _) {
        // Internal palette for the UI
        const Color pPurple = Color(0xFF6C63FF);
        const Color pWhite = Colors.white;

        return Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner Circle - Animated for smooth changes
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pWhite,
                      boxShadow: [
                        BoxShadow(
                          color: pPurple.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: imageNotifier.hasImage
                            ? pPurple
                            : pPurple.withOpacity(0.2),
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: imageNotifier.selectedImage != null
                            ? Image.file(
                                imageNotifier.selectedImage!,
                                key: ValueKey(
                                  imageNotifier.selectedImage!.path,
                                ),
                                width: 110.w,
                                height: 110.w,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.person_rounded,
                                key: const ValueKey('placeholder'),
                                size: 55.w,
                                color: pPurple.withOpacity(0.3),
                              ),
                      ),
                    ),
                  ),

                  // Interactive Edit Button
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: imageNotifier.isLoading
                          ? null
                          : () => _showImageSourceSheet(imageNotifier),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: pPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: pWhite, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: imageNotifier.isLoading
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: pWhite,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18.w,
                                  color: pWhite,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Dynamic Status Message
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: imageNotifier.errorMessage != null
                  ? Text(
                      imageNotifier.errorMessage!,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : imageNotifier.hasImage
                  ? Text(
                      "Looking good!",
                      style: TextStyle(
                        color: pPurple,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Text(
                      "Add a profile photo",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
  // ─── Reusable widgets ─────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Container(height: 1, color: _card.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(color: _white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: readOnly
            ? _card.withValues(alpha: 0.25)
            : _card.withValues(alpha: 0.25),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: const Icon(Icons.person_outline, color: _accent),
        filled: true,
        fillColor: _card.withValues(alpha: 0.25),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
      hint: const Text('Select gender'),
      dropdownColor: _bg,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      borderRadius: BorderRadius.circular(14),
      items: _genderOptions
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedGender = val),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _userTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUserType,
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        prefixIcon: const Icon(Icons.work_outline_rounded, color: _accent),
        filled: true,
        fillColor: _card.withValues(alpha: 0.25),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
      hint: const Text('Select role', style: TextStyle(color: Colors.white30)),
      dropdownColor: _bg,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      borderRadius: BorderRadius.circular(14),
      items: _userTypeOptions
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedUserType = val),
    );
  }

  Widget _dobPicker() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initial = _dobController.text.isNotEmpty
            ? DateTime.tryParse(_dobController.text) ?? now
            : DateTime(now.year - 18);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1940),
          lastDate: DateTime(now.year - 10),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _accent,
                onPrimary: _white,
                surface: Color(0xFF040326),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _dobController.text =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dobController,
          style: const TextStyle(color: _white, fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            hintText: 'YYYY-MM-DD',
            labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            prefixIcon: const Icon(
              Icons.cake_outlined,
              color: _accent,
              size: 20,
            ),
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: _accent,
              size: 16,
            ),
            filled: true,
            fillColor: _card.withValues(alpha: 0.25),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _skillsInput() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: TextFormField(
  //           controller: _skillController,
  //           style: const TextStyle(color: _white, fontSize: 15),
  //           onFieldSubmitted: (_) => _addSkill(),
  //           decoration: InputDecoration(
  //             labelText: 'Add a skill',
  //             hintText: 'e.g. Flutter, Python',
  //             labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
  //             hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
  //             prefixIcon: const Icon(
  //               Icons.psychology_outlined,
  //               color: _accent,
  //               size: 20,
  //             ),
  //             filled: true,
  //             fillColor: _card.withValues(alpha: 0.25),
  //             contentPadding: EdgeInsets.symmetric(
  //               horizontal: 16.w,
  //               vertical: 16.h,
  //             ),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(14),
  //               borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(14),
  //               borderSide: BorderSide(color: _card.withValues(alpha: 0.4)),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(14),
  //               borderSide: const BorderSide(color: _accent, width: 1.5),
  //             ),
  //           ),
  //         ),
  //       ),
  //       SizedBox(width: 10.w),
  //       GestureDetector(
  //         onTap: _addSkill,
  //         child: Container(
  //           height: 54.h,
  //           width: 54.h,
  //           decoration: BoxDecoration(
  //             color: _card,
  //             borderRadius: BorderRadius.circular(14),
  //           ),
  //           child: const Icon(Icons.add_rounded, color: _white, size: 24),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _skillsChips() {
  //   if (skills.isEmpty) {
  //     return Container(
  //       width: double.infinity,
  //       padding: EdgeInsets.all(14.h),
  //       decoration: BoxDecoration(
  //         color: _card.withValues(alpha: 0.15),
  //         borderRadius: BorderRadius.circular(14),
  //         border: Border.all(color: _card.withValues(alpha: 0.3)),
  //       ),
  //       child: const Text(
  //         'No skills added yet',
  //         style: TextStyle(color: Colors.white38, fontSize: 14),
  //         textAlign: TextAlign.center,
  //       ),
  //     );
  //   }

  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.all(14.h),
  //     decoration: BoxDecoration(
  //       color: _card.withValues(alpha: 0.15),
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: _card.withValues(alpha: 0.3)),
  //     ),
  //     child: Wrap(
  //       spacing: 8,
  //       runSpacing: 8,
  //       children: skills.map((skill) {
  //         return Container(
  //           padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //           decoration: BoxDecoration(
  //             color: _card,
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 skill,
  //                 style: const TextStyle(
  //                   color: _white,
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //               SizedBox(width: 6.w),
  //               GestureDetector(
  //                 onTap: () => setState(() => skills.remove(skill)),
  //                 child: const Icon(
  //                   Icons.close_rounded,
  //                   size: 14,
  //                   color: Colors.white70,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  void _showImageSourceSheet(ImageNotifier imageNotifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Change Photo',
                style: TextStyle(
                  color: _white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              _sourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  imageNotifier.pickImage(source: ImageSource.camera);
                },
              ),
              SizedBox(height: 10.h),
              _sourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  imageNotifier.pickImage(source: ImageSource.gallery);
                },
              ),
              SizedBox(height: 6.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: _card.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _card.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accent, size: 22),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                color: _white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(
    String label,
    VoidCallback? onTap, {
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: onTap == null ? _card.withValues(alpha: 0.4) : _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: _card.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
