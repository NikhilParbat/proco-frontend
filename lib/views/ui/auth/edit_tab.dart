import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/image_provider.dart';
import 'package:proco/views/ui/auth/profile_state.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:proco/views/ui/auth/location_picker_screen.dart';
import 'package:proco/services/location_service.dart';

class EditTab extends StatefulWidget {
  const EditTab({super.key});

  @override
  State<EditTab> createState() => _EditTabState();
}

class _EditTabState extends State<EditTab> {
  static const Color _bg = Color(0xFF040326);
  static const Color _card = Color(0xFF0D1B2A);
  static const Color _teal = kTeal;
  static const Color _tealLight = kTealLight;
  static const Color _white = Colors.white;

  static const List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  static const List<String> _userTypeOptions = [
    'Student',
    'Young Professional',
  ];

  final _formKey = GlobalKey<FormState>();

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late TextEditingController _phoneCtrl;
  String? _dobDay;
  String? _dobMonth;
  String? _dobYear;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _collegeCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _linkedInCtrl;
  late TextEditingController _gitHubCtrl;
  late TextEditingController _twitterCtrl;
  late TextEditingController _portfolioCtrl;
  final _skillCtrl = TextEditingController();

  String? _selectedGender;
  String? _selectedUserType;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = context.read<ProfileEditState>();
      _phoneCtrl = TextEditingController(text: s.phone);
      // Parse stored "YYYY-MM-DD" into the three dropdown values
      if (s.dob.isNotEmpty) {
        final parts = s.dob.split('-');
        if (parts.length == 3) {
          _dobYear  = parts[0];
          final mi  = int.tryParse(parts[1]);
          _dobMonth = (mi != null && mi >= 1 && mi <= 12) ? _months[mi - 1] : null;
          _dobDay   = parts[2];
        }
      }
      _cityCtrl = TextEditingController(text: s.city);
      _stateCtrl = TextEditingController(text: s.state);
      _countryCtrl = TextEditingController(text: s.country);
      _collegeCtrl = TextEditingController(text: s.college);
      _branchCtrl = TextEditingController(text: s.branch);
      _linkedInCtrl = TextEditingController(text: s.linkedInUrl);
      _gitHubCtrl = TextEditingController(text: s.gitHubUrl);
      _twitterCtrl = TextEditingController(text: s.twitterUrl);
      _portfolioCtrl = TextEditingController(text: s.portfolioUrl);
      _selectedGender = _genderOptions.contains(s.gender) ? s.gender : null;
      _selectedUserType = _userTypeOptions.contains(s.userType) ? s.userType : null;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _collegeCtrl.dispose();
    _branchCtrl.dispose();
    _linkedInCtrl.dispose();
    _gitHubCtrl.dispose();
    _twitterCtrl.dispose();
    _portfolioCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<ProfileEditState>();
    s.setField('phone', _phoneCtrl.text.trim());
    if (_dobDay != null && _dobMonth != null && _dobYear != null) {
      final mi = (_months.indexOf(_dobMonth!) + 1).toString().padLeft(2, '0');
      s.setField('dob', '$_dobYear-$mi-$_dobDay');
    }
    s.setField('city', _cityCtrl.text.trim());
    s.setField('state', _stateCtrl.text.trim());
    s.setField('country', _countryCtrl.text.trim());
    s.setField('college', _collegeCtrl.text.trim());
    s.setField('branch', _branchCtrl.text.trim());
    s.setField('linkedin', _linkedInCtrl.text.trim());
    s.setField('github', _gitHubCtrl.text.trim());
    s.setField('twitter', _twitterCtrl.text.trim());
    s.setField('portfolio', _portfolioCtrl.text.trim());
    s.setField('gender', _selectedGender ?? '');
    s.setField('userType', _selectedUserType ?? '');

    final imageNotifier = context.read<ImageNotifier>();
    final ok = await s.saveProfile(imageNotifier.selectedImage);
    if (!mounted) return;
    if (ok) {
      Get.snackbar(
        'Saved',
        'Profile updated successfully',
        colorText: _white,
        backgroundColor: kLightBlue,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Get.offAll(() => const MainScreen());
    } else {
      Get.snackbar(
        'Error',
        s.error ?? 'Update failed',
        colorText: _white,
        backgroundColor: kLightBlue,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileEditState>();
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────────────
              _buildAvatarPicker(),
              SizedBox(height: 20.h),

              // ── Personal Info ─────────────────────────────────────────────
              _sectionDivider('Personal Info'),
              SizedBox(height: 12.h),
              _emailReadOnlyWithToggle(state),
              SizedBox(height: 10.h),
              _fieldWithToggle(
                controller: _phoneCtrl,
                label: 'Phone',
                icon: Icons.phone_outlined,
                visKey: 'phone',
                isVisible: state.showPhone,
                state: state,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (v) {
                  if (v != null &&
                      v.isNotEmpty &&
                      !RegExp(r'^\d{10,15}$').hasMatch(v)) {
                    return 'Enter a valid phone number (10–15 digits)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              _genderRowWithToggle(state),
              SizedBox(height: 10.h),
              _dobSectionWithToggle(state),
              SizedBox(height: 10.h),
              _userTypeRowWithToggle(state),
              SizedBox(height: 20.h),

              // ── Location ──────────────────────────────────────────────────
              _sectionDivider('Location'),
              SizedBox(height: 8.h),
              Text(
                'Use the map pin for automatic detection, or fill in manually.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11.sp,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () async {
                  final LatLng? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerScreen(
                        initialPosition: LatLng(
                          state.latitude,
                          state.longitude,
                        ),
                      ),
                    ),
                  );

                  if (result != null) {
                    final address = await LocationService.getAddressFromLatLng(
                      result.latitude,
                      result.longitude,
                    );
                    setState(() {
                      _cityCtrl.text    = address.city;
                      _stateCtrl.text   = address.state;
                      _countryCtrl.text = address.country;
                      state.setCoordinates(result.latitude, result.longitude);
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(14.h),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _teal.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: _teal),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Text(
                          'Auto-detect via Map',
                          style: TextStyle(
                            color: _tealLight,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _teal),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Country — searchable dropdown
              _countryPickerField(),
              SizedBox(height: 10.h),
              // State — editable text
              _plainField(
                controller: _stateCtrl,
                label: 'State / Province',
                hint: 'e.g. Maharashtra',
                icon: Icons.map_outlined,
              ),
              SizedBox(height: 10.h),
              // City — editable text
              _plainField(
                controller: _cityCtrl,
                label: 'City',
                hint: 'e.g. Mumbai',
                icon: Icons.location_city_outlined,
              ),
              SizedBox(height: 20.h),

              // ── Education ─────────────────────────────────────────────────
              _sectionDivider('Education'),
              SizedBox(height: 12.h),
              _fieldWithToggle(
                controller: _collegeCtrl,
                label: 'College / University',
                icon: Icons.apartment_outlined,
                visKey: 'college',
                isVisible: state.showCollege,
                state: state,
                inputFormatters: [noEmojiFormatter],
              ),
              SizedBox(height: 10.h),
              _plainField(
                controller: _branchCtrl,
                label: 'Branch / Field of Study',
                hint: 'e.g. Computer Science',
                icon: Icons.school_outlined,
                maxLength: 100,
                inputFormatters: [noEmojiFormatter],
              ),
              SizedBox(height: 20.h),

              // ── Skills ────────────────────────────────────────────────────
              _sectionDivider('Skills'),
              SizedBox(height: 8.h),
              _skillsToggleRow(state),
              SizedBox(height: 10.h),
              _skillsInput(state),
              SizedBox(height: 10.h),
              _skillsChips(state),
              SizedBox(height: 20.h),

              // ── Social / URLs ─────────────────────────────────────────────
              _sectionDivider('Social & Links'),
              SizedBox(height: 12.h),
              _fieldWithToggle(
                controller: _linkedInCtrl,
                label: 'LinkedIn URL',
                icon: Icons.link_rounded,
                visKey: 'linkedin',
                isVisible: state.showLinkedIn,
                state: state,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 10.h),
              _fieldWithToggle(
                controller: _gitHubCtrl,
                label: 'GitHub URL',
                icon: Icons.code_rounded,
                visKey: 'github',
                isVisible: state.showGitHub,
                state: state,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 10.h),
              _fieldWithToggle(
                controller: _twitterCtrl,
                label: 'Twitter / X URL',
                icon: Icons.alternate_email_rounded,
                visKey: 'twitter',
                isVisible: state.showTwitter,
                state: state,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 10.h),
              _fieldWithToggle(
                controller: _portfolioCtrl,
                label: 'Portfolio URL',
                icon: Icons.language_rounded,
                visKey: 'portfolio',
                isVisible: state.showPortfolio,
                state: state,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 28.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: SafeArea(child: _saveButton(state)),
      ),
    );
  }

  // ── Country picker field ───────────────────────────────────────────────────
  static const List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Argentina',
    'Armenia', 'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain',
    'Bangladesh', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan',
    'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei',
    'Bulgaria', 'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon', 'Canada',
    'Cape Verde', 'Central African Republic', 'Chad', 'Chile', 'China',
    'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba',
    'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominican Republic',
    'DR Congo', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea',
    'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji', 'Finland',
    'France', 'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece',
    'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras',
    'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland',
    'Israel', 'Italy', 'Ivory Coast', 'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kosovo', 'Kuwait', 'Kyrgyzstan', 'Laos',
    'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein',
    'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi', 'Malaysia',
    'Maldives', 'Mali', 'Malta', 'Mauritania', 'Mauritius', 'Mexico',
    'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique',
    'Myanmar', 'Namibia', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua',
    'Niger', 'Nigeria', 'North Korea', 'North Macedonia', 'Norway', 'Oman',
    'Pakistan', 'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay',
    'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania',
    'Russia', 'Rwanda', 'Saudi Arabia', 'Senegal', 'Serbia', 'Sierra Leone',
    'Singapore', 'Slovakia', 'Slovenia', 'Somalia', 'South Africa',
    'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname',
    'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan', 'Tanzania',
    'Thailand', 'Timor-Leste', 'Togo', 'Trinidad and Tobago', 'Tunisia',
    'Turkey', 'Turkmenistan', 'Uganda', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Venezuela',
    'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
  ];

  Widget _countryPickerField() {
    final current = _countryCtrl.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              'Country',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        GestureDetector(
          onTap: () => _showCountryPicker(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _teal.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current.isNotEmpty ? current : 'Select country',
                    style: TextStyle(
                      color: current.isNotEmpty ? _white : Colors.white24,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _teal,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollCtrl) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: Column(
                    children: [
                      // handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        'Select Country',
                        style: TextStyle(
                          color: _white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Search
                      TextField(
                        controller: searchCtrl,
                        style: TextStyle(color: _white, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: 'Search country...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search, color: _teal),
                          filled: true,
                          fillColor: const Color(0xFF040326),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _teal.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _teal.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (q) {
                          setSheetState(() {
                            filtered = _countries
                                .where(
                                  (c) => c.toLowerCase().contains(
                                    q.toLowerCase(),
                                  ),
                                )
                                .toList();
                          });
                        },
                      ),
                      SizedBox(height: 8.h),
                      // List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final country = filtered[i];
                            final selected = country == _countryCtrl.text;
                            return InkWell(
                              onTap: () {
                                setState(() => _countryCtrl.text = country);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _teal.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        country,
                                        style: TextStyle(
                                          color: selected ? _teal : _white,
                                          fontSize: 14.sp,
                                          fontFamily: 'Poppins',
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: _teal,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Avatar picker ──────────────────────────────────────────────────────────
  void _showImageSourceSheet(ImageNotifier imageNotifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
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
                  fontFamily: 'Poppins',
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
          color: _teal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _teal, size: 22),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                color: _white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    final state = context.watch<ProfileEditState>();
    return Consumer<ImageNotifier>(
      builder: (context, imageNotifier, _) {
        // Determine what to display in the circle:
        //  1. Newly picked local file (highest priority)
        //  2. Existing profile image from backend
        //  3. Fallback person icon
        final hasNewImage   = imageNotifier.selectedImage != null;
        final hasNetworkImg = state.profileImageUrl.isNotEmpty &&
            state.profileImageUrl != 'null';

        Widget avatarChild;
        if (hasNewImage) {
          avatarChild = ClipOval(
            child: Image.file(
              imageNotifier.selectedImage!,
              fit: BoxFit.cover,
              width: 86.w,
              height: 86.w,
            ),
          );
        } else if (hasNetworkImg) {
          avatarChild = ClipOval(
            child: CachedNetworkImage(
              imageUrl: state.profileImageUrl,
              fit: BoxFit.cover,
              width: 86.w,
              height: 86.w,
              placeholder: (context, url) => Icon(
                Icons.person_rounded,
                size: 42.w,
                color: _teal.withValues(alpha: 0.5),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.person_rounded,
                size: 42.w,
                color: _teal.withValues(alpha: 0.5),
              ),
            ),
          );
        } else {
          avatarChild = Icon(
            Icons.person_rounded,
            size: 42.w,
            color: _teal.withValues(alpha: 0.5),
          );
        }

        return Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 86.w,
                height: 86.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _card,
                  border: Border.all(color: _teal, width: 2.5),
                ),
                child: avatarChild,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: imageNotifier.isLoading
                      ? null
                      : () => _showImageSourceSheet(imageNotifier),
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bg, width: 2),
                    ),
                    child: imageNotifier.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 13,
                            color: _white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Section divider label ──────────────────────────────────────────────────
  Widget _sectionDivider(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16.h,
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            color: _white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  // ── Email read-only row with visibility toggle ────────────────────────────
  Widget _emailReadOnlyWithToggle(ProfileEditState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.email_outlined, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              'Email',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              state.showEmail ? 'Visible' : 'Hidden',
              style: TextStyle(
                color: state.showEmail ? _tealLight : Colors.white38,
                fontSize: 11.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              height: 24,
              child: Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: state.showEmail,
                  onChanged: (_) => state.toggleVisibility('email'),
                  activeThumbColor: _teal,
                  activeTrackColor: _teal.withValues(alpha:0.3),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: _card.withValues(alpha:0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _teal.withValues(alpha:0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: _teal.withValues(alpha:0.5),
                size: 14,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  state.email.isNotEmpty ? state.email : '—',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14.sp,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Field with inline visibility toggle ───────────────────────────────────
  Widget _fieldWithToggle({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String visKey,
    required bool isVisible,
    required ProfileEditState state,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row + toggle
        Row(
          children: [
            Icon(icon, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              isVisible ? 'Visible' : 'Hidden',
              style: TextStyle(
                color: isVisible ? _tealLight : Colors.white38,
                fontSize: 11.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              height: 24,
              child: Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: isVisible,
                  onChanged: (_) => state.toggleVisibility(visKey),
                  activeThumbColor: _teal,
                  activeTrackColor: _teal.withValues(alpha:0.3),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        // Text field
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: _white, fontSize: 14.sp),
          validator: validator,
          decoration: _fieldDecoration(hint ?? label),
        ),
      ],
    );
  }

  // ── Plain field (no toggle) ────────────────────────────────────────────────
  Widget _plainField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: TextStyle(color: _white, fontSize: 14.sp),
          validator: validator,
          decoration: _fieldDecoration(hint ?? label),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      filled: true,
      fillColor: _card,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _teal.withValues(alpha:0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _teal.withValues(alpha:0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // ── Gender row with toggle ─────────────────────────────────────────────────
  Widget _genderRowWithToggle(ProfileEditState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wc_outlined, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              'Gender',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              state.showGender ? 'Visible' : 'Hidden',
              style: TextStyle(
                color: state.showGender ? _tealLight : Colors.white38,
                fontSize: 11.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              height: 24,
              child: Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: state.showGender,
                  onChanged: (_) => state.toggleVisibility('gender'),
                  activeThumbColor: _teal,
                  activeTrackColor: _teal.withValues(alpha:0.3),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: InputDecoration(
            hintText: 'Select gender',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: _teal,
              size: 18,
            ),
            filled: true,
            fillColor: _card,
            contentPadding: EdgeInsets.symmetric(
              vertical: 13.h,
              horizontal: 14.w,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _teal.withValues(alpha:0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _teal.withValues(alpha:0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal, width: 1.5),
            ),
          ),
          dropdownColor: const Color(0xFF0D2233),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _teal),
          style: TextStyle(color: _white, fontSize: 14.sp),
          borderRadius: BorderRadius.circular(12),
          items: _genderOptions
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(g, style: const TextStyle(color: _white)),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ],
    );
  }

  // ── User type (Role) row with visibility toggle ───────────────────────────
  Widget _userTypeRowWithToggle(ProfileEditState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              'Role',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              state.showUserType ? 'Visible' : 'Hidden',
              style: TextStyle(
                color: state.showUserType ? _tealLight : Colors.white38,
                fontSize: 11.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              height: 24,
              child: Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: state.showUserType,
                  onChanged: (_) => state.toggleVisibility('usertype'),
                  activeThumbColor: _teal,
                  activeTrackColor: _teal.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        DropdownButtonFormField<String>(
          value: _selectedUserType,
          decoration: InputDecoration(
            hintText: 'Select role',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(
              Icons.work_outline_rounded,
              color: _teal,
              size: 18,
            ),
            filled: true,
            fillColor: _card,
            contentPadding: EdgeInsets.symmetric(
              vertical: 13.h,
              horizontal: 14.w,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _teal.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _teal.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal, width: 1.5),
            ),
          ),
          dropdownColor: const Color(0xFF0D2233),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _teal),
          style: TextStyle(color: _white, fontSize: 14.sp),
          borderRadius: BorderRadius.circular(12),
          items: _userTypeOptions
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(color: _white)),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedUserType = val),
        ),
      ],
    );
  }

  // ── DOB section with visibility toggle ────────────────────────────────────
  Widget _dobSectionWithToggle(ProfileEditState state) {
    final days   = List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));
    final years  = List.generate(
      DateTime.now().year - 13 - 1949,
      (i) => (DateTime.now().year - 13 - i).toString(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label + visibility toggle ──────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.cake_outlined, color: _teal, size: 15),
            SizedBox(width: 6.w),
            Text(
              'Date of Birth',
              style: TextStyle(color: Colors.white60, fontSize: 12.sp, fontFamily: 'Poppins'),
            ),
            const Spacer(),
            Text(
              state.showDob ? 'Visible' : 'Hidden',
              style: TextStyle(
                color: state.showDob ? _tealLight : Colors.white38,
                fontSize: 11.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              height: 24,
              child: Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: state.showDob,
                  onChanged: (_) => state.toggleVisibility('dob'),
                  activeThumbColor: _teal,
                  activeTrackColor: _teal.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        // ── Three dropdowns ────────────────────────────────────────────────
        Row(
          children: [
            // Day
            Expanded(
              flex: 2,
              child: _dobDropdown(
                hint: 'Day',
                value: _dobDay,
                items: days,
                onChanged: (v) => setState(() => _dobDay = v),
              ),
            ),
            SizedBox(width: 8.w),
            // Month
            Expanded(
              flex: 3,
              child: _dobDropdown(
                hint: 'Month',
                value: _dobMonth,
                items: _months,
                onChanged: (v) => setState(() => _dobMonth = v),
              ),
            ),
            SizedBox(width: 8.w),
            // Year
            Expanded(
              flex: 3,
              child: _dobDropdown(
                hint: 'Year',
                value: _dobYear,
                items: years,
                onChanged: (v) => setState(() => _dobYear = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dobDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF0D2233),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _teal, size: 18),
      style: TextStyle(color: _white, fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: _card,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 13.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _teal.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _teal.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    );
  }

  // ── Skills toggle row ──────────────────────────────────────────────────────
  Widget _skillsToggleRow(ProfileEditState state) {
    return Row(
      children: [
        const Icon(Icons.psychology_outlined, color: _teal, size: 15),
        SizedBox(width: 6.w),
        Text(
          'Skills',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12.sp,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        Text(
          state.showSkills ? 'Visible' : 'Hidden',
          style: TextStyle(
            color: state.showSkills ? _tealLight : Colors.white38,
            fontSize: 11.sp,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(width: 2.w),
        SizedBox(
          height: 24,
          child: Transform.scale(
            scale: 0.75,
            child: Switch(
              value: state.showSkills,
              onChanged: (_) => state.toggleVisibility('skills'),
              activeThumbColor: _teal,
              activeTrackColor: _teal.withValues(alpha:0.3),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ),
        ),
      ],
    );
  }

  // ── Skills input ───────────────────────────────────────────────────────────
  Widget _skillsInput(ProfileEditState state) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _skillCtrl,
            style: TextStyle(color: _white, fontSize: 14.sp),
            onFieldSubmitted: (_) => _addSkill(state),
            decoration: InputDecoration(
              hintText: 'Add a skill (e.g. Flutter)',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(
                Icons.add_circle_outline_rounded,
                color: _teal,
                size: 18,
              ),
              filled: true,
              fillColor: _card,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 13.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _teal.withValues(alpha:0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _teal.withValues(alpha:0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _teal, width: 1.5),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => _addSkill(state),
          child: Container(
            height: 46.h,
            width: 46.h,
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: _white, size: 20),
          ),
        ),
      ],
    );
  }

  void _addSkill(ProfileEditState state) {
    final skill = _skillCtrl.text.trim();
    if (skill.isEmpty) return;
    state.addSkill(skill);
    _skillCtrl.clear();
  }

  // ── Skills chips ───────────────────────────────────────────────────────────
  Widget _skillsChips(ProfileEditState state) {
    if (state.skills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: _teal.withValues(alpha:0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _teal.withValues(alpha:0.2)),
        ),
        child: Text(
          'No skills added yet',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12.sp,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.h),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha:0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withValues(alpha:0.2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: state.skills.map((skill) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha:0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _teal.withValues(alpha:0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  skill,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 5.w),
                GestureDetector(
                  onTap: () => state.removeSkill(skill),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────
  Widget _saveButton(ProfileEditState state) {
    return GestureDetector(
      onTap: state.isSaving ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: state.isSaving
                ? [_teal.withValues(alpha:0.4), _teal.withValues(alpha:0.4)]
                : [kTeal, kTealLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: state.isSaving
              ? []
              : [
                  BoxShadow(
                    color: _teal.withValues(alpha:0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: state.isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _white,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: _white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }
}
