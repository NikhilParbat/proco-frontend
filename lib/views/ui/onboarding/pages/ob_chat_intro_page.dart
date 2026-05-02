import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/ui/mainscreen.dart';

// ── Colour helpers ─────────────────────────────────────────────────────────────

const _kBotBubble = kThemeColor; // salmon – left / bot side
const _kUserBubble = Color.fromARGB(200, 216, 87, 87); // lighter tint – right / user side

// ── Data ───────────────────────────────────────────────────────────────────────

const _kSkills = [
  'Flutter', 'Python', 'Java', 'Design', 'JavaScript', 'Node.js',
  'React', 'Firebase', 'SQL', 'Communication', 'Product Mgmt',
  'Marketing', 'UI/UX', 'Machine Learning', 'Kotlin', 'Swift',
];

const _kInterests = [
  'Photography', 'Chess', 'Football', 'Reading', 'Music',
  'Gaming', 'Hiking', 'Writing', 'Cooking', 'Gardening',
  'Travelling', 'Painting', 'Fitness', 'Dance',
];

const _kDegrees = [
  'B.Tech / CSE', 'B.Tech / ECE', 'B.Tech / ME', 'B.Tech / Civil',
  'B.Tech / IT', 'B.Tech / EEE', 'M.Tech', 'MBA', 'BBA',
  'B.Com', 'B.Sc', 'M.Sc', 'BCA', 'MCA', 'B.Arch', 'Ph.D',
  'Diploma', 'Other',
];

const _kGenders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

// ── Message model ──────────────────────────────────────────────────────────────

class _Msg {
  const _Msg({required this.isBot, required this.text});
  final bool isBot;
  final String text;
}

// ── Page ───────────────────────────────────────────────────────────────────────

class ObChatIntroPage extends StatefulWidget {
  const ObChatIntroPage({super.key});

  @override
  State<ObChatIntroPage> createState() => _ObChatIntroPageState();
}

class _ObChatIntroPageState extends State<ObChatIntroPage> {
  final _scrollCtrl = ScrollController();
  final List<_Msg> _msgs = [];
  int _step = 0; // 0-4; 5 = done

  // Step 0: Basics
  final _nameCtrl = TextEditingController();
  String _gender = '';
  DateTime? _dob;

  // Step 1: Education
  String _degree = '';
  final _collegeCtrl = TextEditingController();
  String _gradYear = '';

  // Step 2: Skills
  final Set<String> _skills = {};
  final _skillSearchCtrl = TextEditingController();
  String _skillQuery = '';

  // Step 3: Interests
  final Set<String> _interests = {};
  final _customInterestCtrl = TextEditingController();

  // Step 4: Photo
  File? _photo;
  bool _picking = false;

  static const List<String> _botQuestions = [
    "Welcome to Lagoon! 👋 Let's get the basics down.\nWhat's your Name, Gender, and Date of Birth?",
    "Great. Now, tell me about your studies.\nWhat's your Degree / Branch, College, and when do you Graduate?",
    "What are you good at? Pick your top skills so we can match you with the right projects.",
    "Want to add some flair? What are your Interests or Hobbies?\n(You can skip this for now).",
    "Time for a selfie! Add a Profile Photo so people recognize you.",
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(const _Msg(isBot: true, text: ''));
    _skillSearchCtrl.addListener(() {
      setState(() => _skillQuery = _skillSearchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _collegeCtrl.dispose();
    _skillSearchCtrl.dispose();
    _customInterestCtrl.dispose();
    super.dispose();
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Advance step ───────────────────────────────────────────────────────────

  void _advance({required String userSummary, bool skipped = false}) {
    final provider = context.read<OnboardingFlowProvider>();

    // Persist collected data into provider
    if (_step == 0) {
      provider.name = _nameCtrl.text.trim();
      if (_dob != null) {
        final m = _dob!.month.toString().padLeft(2, '0');
        final d = _dob!.day.toString().padLeft(2, '0');
        provider.dob = '${_dob!.year}-$m-$d';
      }
    } else if (_step == 1) {
      provider.institution = _collegeCtrl.text.trim();
    } else if (_step == 2) {
      provider.skills = List.from(_skills);
    } else if (_step == 4) {
      if (_photo != null) provider.profilePhoto = _photo;
    }

    setState(() {
      _msgs.add(_Msg(isBot: false, text: userSummary));
      _step++;
      if (_step < _botQuestions.length) {
        _msgs.add(const _Msg(isBot: true, text: ''));
      }
    });

    _scrollToBottom();

    if (_step >= _botQuestions.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) provider.submit();
      });
    }
  }

  // ── Validate + collect per step ────────────────────────────────────────────

  void _onContinue() {
    switch (_step) {
      case 0:
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) {
          _snack('Name required', 'Please enter your full name.');
          return;
        }
        if (_gender.isEmpty) {
          _snack('Gender required', 'Please select your gender.');
          return;
        }
        if (_dob == null) {
          _snack('Date of birth required', 'Please pick your date of birth.');
          return;
        }
        final dobStr =
            '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';
        _advance(userSummary: '$name, $_gender, $dobStr');

      case 1:
        if (_degree.isEmpty) {
          _snack('Degree required', 'Please select your degree / branch.');
          return;
        }
        final college = _collegeCtrl.text.trim();
        if (college.isEmpty) {
          _snack('College required', 'Please enter your college name.');
          return;
        }
        if (_gradYear.isEmpty) {
          _snack('Graduation year required', 'Please select your graduation year.');
          return;
        }
        _advance(userSummary: '$_degree, $college, $_gradYear');

      case 2:
        if (_skills.isEmpty) {
          _snack('Select skills', 'Pick at least one skill.');
          return;
        }
        _advance(userSummary: _skills.join(', '));

      case 3:
        _advance(
          userSummary:
              _interests.isEmpty ? 'Skipped' : _interests.join(', '),
          skipped: _interests.isEmpty,
        );

      case 4:
        _advance(
          userSummary: _photo != null ? 'Profile photo added' : 'Skipped',
          skipped: _photo == null,
        );
    }
  }

  // ── Photo picker ───────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final perm = source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await perm.request();
    if (!status.isGranted && !status.isLimited) {
      if (status.isPermanentlyDenied) openAppSettings();
      return;
    }
    setState(() => _picking = true);
    try {
      final result = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (result != null && mounted) setState(() => _photo = File(result.path));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // ── DOB picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 13),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kThemeColor,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── Grad year picker ───────────────────────────────────────────────────────

  List<String> get _gradYears {
    final now = DateTime.now().year;
    return List.generate(10, (i) => (now - 2 + i).toString());
  }

  // ── Skip to home ───────────────────────────────────────────────────────────

  void _skipToHome() {
    Get.offAll(() => const MainScreen(), transition: Transition.fade);
  }

  void _snack(String t, String m) =>
      Get.snackbar(t, m, backgroundColor: kOrange, colorText: kLight);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: kBackgroundColor,
        child: Column(
          children: [
            LagoonAppBar(
              actions: [
                GestureDetector(
                  onTap: _skipToHome,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: Center(
                      child: Text(
                        'Skip All',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(child: _buildChatList()),
                    if (_step < _botQuestions.length) _buildInputArea(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat list ──────────────────────────────────────────────────────────────

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _msgs.length,
      itemBuilder: (ctx, i) {
        final msg = _msgs[i];
        return msg.isBot ? _BotBubble(text: _botQuestions[i ~/ 2]) : _UserBubble(text: msg.text);
      },
    );
  }

  // ── Input area (switches per step) ─────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepInput(),
          SizedBox(height: 14.h),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildStepInput() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Basics ─────────────────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(
          controller: _nameCtrl,
          hint: 'Full Name',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 10.h),
        _DropdownInput<String>(
          hint: 'Gender',
          icon: Icons.wc_outlined,
          value: _gender.isEmpty ? null : _gender,
          items: _kGenders,
          onChanged: (v) => setState(() => _gender = v ?? ''),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: _pickDob,
          child: _InputDisplay(
            icon: Icons.calendar_today_outlined,
            text: _dob == null
                ? 'Date of Birth'
                : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}',
            isPlaceholder: _dob == null,
          ),
        ),
      ],
    );
  }

  // ── Step 1: Education ──────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropdownInput<String>(
          hint: 'Degree / Branch',
          icon: Icons.school_outlined,
          value: _degree.isEmpty ? null : _degree,
          items: _kDegrees,
          onChanged: (v) => setState(() => _degree = v ?? ''),
        ),
        SizedBox(height: 10.h),
        _InputField(
          controller: _collegeCtrl,
          hint: 'College Name',
          icon: Icons.search,
        ),
        SizedBox(height: 10.h),
        _DropdownInput<String>(
          hint: 'Graduation Year',
          icon: Icons.event_outlined,
          value: _gradYear.isEmpty ? null : _gradYear,
          items: _gradYears,
          onChanged: (v) => setState(() => _gradYear = v ?? ''),
        ),
      ],
    );
  }

  // ── Step 2: Skills ─────────────────────────────────────────────────────────

  Widget _buildStep2() {
    final filtered = _kSkills
        .where((s) => s.toLowerCase().contains(_skillQuery))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(
          controller: _skillSearchCtrl,
          hint: 'Search Skills',
          icon: Icons.search,
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: filtered.map((s) {
            final selected = _skills.contains(s);
            return GestureDetector(
              onTap: () => setState(() {
                selected ? _skills.remove(s) : _skills.add(s);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: selected ? kThemeColor : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: selected ? kThemeColor : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 13.sp,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(width: 4.w),
                      const Icon(Icons.check, size: 14, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_skills.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              '${_skills.length} selected',
              style: TextStyle(
                color: kThemeColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ── Step 3: Interests ──────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            ..._kInterests.map((s) {
              final selected = _interests.contains(s);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _interests.remove(s) : _interests.add(s);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: selected ? kThemeColor : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: selected ? kThemeColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13.sp,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            // "Skip" as a chip
            GestureDetector(
              onTap: () => _advance(userSummary: 'Skipped', skipped: true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.add, size: 16.sp, color: kThemeColor),
            SizedBox(width: 6.w),
            Expanded(
              child: TextField(
                controller: _customInterestCtrl,
                style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Add other interest',
                  hintStyle:
                      TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (v) {
                  final val = v.trim();
                  if (val.isNotEmpty) {
                    setState(() {
                      _interests.add(val);
                      _customInterestCtrl.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 4: Photo ──────────────────────────────────────────────────────────

  Widget _buildStep4() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickPhoto(ImageSource.gallery),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: _photo != null ? kThemeColor : Colors.grey.shade300,
                    width: 2,
                  ),
                  image: _photo != null
                      ? DecorationImage(
                          image: FileImage(_photo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _photo == null
                    ? Icon(
                        Icons.camera_alt_outlined,
                        size: 36.sp,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
              if (_picking)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: kThemeColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kThemeColor,
                  ),
                  child: Icon(Icons.add, size: 16.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Tap to upload or take a photo',
          style: TextStyle(fontSize: 13.sp, color: Colors.black54),
        ),
        Text(
          'Supports JPG, PNG up to 5MB',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PhotoSourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: _picking ? null : () => _pickPhoto(ImageSource.gallery),
            ),
            SizedBox(width: 12.w),
            _PhotoSourceButton(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: _picking ? null : () => _pickPhoto(ImageSource.camera),
            ),
            SizedBox(width: 12.w),
            // Skip as a button/chip
            GestureDetector(
              onTap: () => _advance(userSummary: 'Skipped', skipped: true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Continue button ────────────────────────────────────────────────────────

  Widget _buildContinueButton() {
    // Steps 3 and 4 have skip chips; no need for skip under button.
    // Steps 0–2 require an answer before continue.
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: _onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: kThemeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Continue',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Chat bubbles ───────────────────────────────────────────────────────────────

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kBotBubble,
            ),
            alignment: Alignment.center,
            child: Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _kBotBubble,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  height: 1.45,
                ),
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(width: 48.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _kUserBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared input widgets ───────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Colors.grey.shade400),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 14.sp, color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownInput<T> extends StatelessWidget {
  const _DropdownInput({
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Colors.grey.shade400),
          SizedBox(width: 8.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                dropdownColor: Colors.white,
                items: items
                    .map((v) => DropdownMenuItem<T>(
                          value: v,
                          child: Text(v.toString()),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputDisplay extends StatelessWidget {
  const _InputDisplay({
    required this.icon,
    required this.text,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String text;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Colors.grey.shade400),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: isPlaceholder ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.calendar_month_outlined, size: 16.sp, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: kThemeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: kThemeColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: kThemeColor),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: kThemeColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
