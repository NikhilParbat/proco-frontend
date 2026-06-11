import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:proco/constants/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/services/location_service.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/skill_search_field.dart';
import 'package:proco/views/common/wave_loader.dart';

// ── Colors ────────────────────────────────────────────────────────────────────

const _kBotBubble = kReceive;
const _kUserBubble = kSend;

// ── Static data ────────────────────────────────────────────────────────────────

const _kDegrees = [
  'B.Tech / B.E.',
  'M.Tech / M.E.',
  'MBA',
  'BBA',
  'B.Com',
  'B.Sc',
  'M.Sc',
  'BCA',
  'MCA',
  'B.Arch',
  'Ph.D',
  'Diploma',
  'Other',
];

const _kBranches = [
  'Computer Science & Engineering',
  'Data Science & Artificial Intelligence',
  'Information Technology',
  'Electronics & Communication Engineering',
  'Electrical Engineering',
  'Mechanical Engineering',
  'Civil Engineering',
  'Business Administration',
  'Finance',
  'Marketing',
  'Physics',
  'Mathematics',
  'Chemistry',
  'Biology',
  'Design / Architecture',
  'Other',
];

const _kGenders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

// ── Message model ──────────────────────────────────────────────────────────────

enum _MsgKind { bot, user, skill }

class _Msg {
  const _Msg({required this.id, required this.kind, required this.text});

  /// Stable id so [ListView] keeps each bubble's animation state when other
  /// bubbles are inserted or removed (e.g. removing a selected skill).
  final int id;
  final _MsgKind kind;
  final String text;
}

// ── Animated message wrapper ───────────────────────────────────────────────────
// Each new bubble slides up and fades in independently.

class _ChatMessage extends StatefulWidget {
  const _ChatMessage({required super.key, required this.child});
  final Widget child;

  @override
  State<_ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<_ChatMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

// ── Typing indicator (three bouncing dots) ─────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _anims = _ctrls
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: -5,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 140), () {
        if (mounted) {
          _ctrls[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: const BoxDecoration(
              color: _kBotBubble,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => AnimatedBuilder(
                  animation: _anims[i],
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _anims[i].value),
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
  int _msgSeq = 0; // monotonic id source for _Msg keys

  // Animation state
  bool _showTyping = false;
  bool _transitioning = false; // blocks input while bot is "replying"
  bool _ready = false; // first question has appeared

  // Step 0: Basics
  final _nameCtrl = TextEditingController();
  String _gender = '';
  DateTime? _dob;

  // Step 1: Education
  String _degree = '';
  String _branch = '';
  final _collegeCtrl = TextEditingController();
  final _cgpaCtrl = TextEditingController();
  String _cgpaScale = '10';
  String _gradYear = '';

  // Step 2: Skills
  final Set<String> _skills = {};
  static const int _kMinSkills = 4;
  static const int _kMaxSkills = 12;

  // Step 3: Location
  final _locationSearchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _locationResults = [];
  bool _isSearchingLocation = false;
  bool _isFetchingCurrentLocation = false;
  String? _selectedLocationLabel;
  bool _preferTypingLocation = false;

  static const List<String> _botQuestions = [
    "Welcome to Lagoon! 👋 Let's get the basics down.\nWhat's your Name, Gender, and Date of Birth?",
    "I have a few questions about your educational background!\nTell me your Institution, Degree, Field of Study, CGPA, and Graduation Year.",
    "What are you good at? Pick your top skills so we can match you with the right projects.",
    "Last step! We need your Location to show you students and opportunities in your area.",
  ];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _collegeCtrl.dispose();
    _cgpaCtrl.dispose();
    _locationSearchCtrl.dispose();
    super.dispose();
  }

  // ── Restore / resume ─────────────────────────────────────────────────────

  Future<void> _restore() async {
    final provider = context.read<OnboardingFlowProvider>();
    await provider.loadDraft();
    if (!mounted) return;
    _hydrateFromProvider(provider);
    // Delay first paint so the page transition finishes before bubbles appear.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _rebuildHistory();
        _ready = true;
      });
      _scrollToBottom();
    });
  }

  /// Copy the saved draft from the provider into local widget state, guarding
  /// each dropdown value against options that no longer exist.
  void _hydrateFromProvider(OnboardingFlowProvider p) {
    _step = p.chatStep.clamp(0, _botQuestions.length);

    _nameCtrl.text = p.name;
    if (_kGenders.contains(p.gender)) _gender = p.gender;
    if (p.dob.isNotEmpty) _dob = DateTime.tryParse(p.dob);

    _collegeCtrl.text = p.institution;
    if (_kDegrees.contains(p.degree)) _degree = p.degree;
    if (_kBranches.contains(p.branch)) _branch = p.branch;
    if (_gradYears.contains(p.classOf)) _gradYear = p.classOf;
    if (p.cgpa.contains('/')) {
      final parts = p.cgpa.split('/');
      _cgpaCtrl.text = parts[0];
      if (parts.length > 1 && const ['4', '10'].contains(parts[1])) {
        _cgpaScale = parts[1];
      }
    } else {
      _cgpaCtrl.text = p.cgpa;
    }

    _skills
      ..clear()
      ..addAll(p.skills);

    if (p.displayAddress.isNotEmpty) {
      _selectedLocationLabel = p.displayAddress;
      _locationSearchCtrl.text = p.displayAddress;
    }
  }

  /// Rebuild the chat transcript from the restored step + answers: each
  /// completed step contributes its question and the user's reply.
  void _rebuildHistory() {
    _msgs.clear();
    for (var k = 0; k <= _step && k < _botQuestions.length; k++) {
      _msgs.add(_Msg(id: _msgSeq++, kind: _MsgKind.bot, text: _botQuestions[k]));
      final completed = k < _step;
      if (k == 2) {
        // Skills render as individual bubbles whether the step is done or live.
        for (final s in _skills) {
          _msgs.add(_Msg(id: _msgSeq++, kind: _MsgKind.skill, text: s));
        }
      } else if (completed) {
        final summary = _summaryForStep(k);
        if (summary.isNotEmpty) {
          _msgs.add(_Msg(id: _msgSeq++, kind: _MsgKind.user, text: summary));
        }
      }
    }
  }

  // ── Persistence helpers ────────────────────────────────────────────────────

  String _isoDob(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Mirror current local state into the provider (location is written
  /// separately via [OnboardingFlowProvider.setLocation]).
  void _commitToProvider(OnboardingFlowProvider p) {
    p.name = _nameCtrl.text.trim();
    p.gender = _gender;
    p.dob = _dob == null ? '' : _isoDob(_dob!);
    p.institution = _collegeCtrl.text.trim();
    p.degree = _degree;
    p.branch = _branch;
    p.classOf = _gradYear;
    p.cgpa = _cgpaCtrl.text.trim().isEmpty
        ? ''
        : '${_cgpaCtrl.text.trim()}/$_cgpaScale';
    p.skills = List.from(_skills);
  }

  // ── Skill selection (step 2) ───────────────────────────────────────────────
  // NB: selections are intentionally NOT persisted here. Like every other
  // step, skills are only saved at the step-completion checkpoint in _advance.

  void _addSkill(String skill) {
    if (_skills.contains(skill)) return;
    if (_skills.length >= _kMaxSkills) {
    _snack(
      'Skill limit reached',
      'You can select a maximum of $_kMaxSkills skills.',
    );
    return;
  }
    setState(() {
      _skills.add(skill);
      _msgs.add(_Msg(id: _msgSeq++, kind: _MsgKind.skill, text: skill));
    });
    _scrollToBottom();
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
      _msgs.removeWhere(
        (m) => m.kind == _MsgKind.skill && m.text == skill,
      );
    });
  }

  String _summaryForStep(int step) {
    switch (step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) return '';
        final dobStr = _dob == null
            ? ''
            : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';
        return '${_nameCtrl.text.trim()}, $_gender, $dobStr';
      case 1:
        final college = _collegeCtrl.text.trim();
        final cgpaText = _cgpaCtrl.text.trim();
        final cgpaSummary = cgpaText.isEmpty
            ? ''
            : ' • CGPA: $cgpaText/$_cgpaScale';
        return '$college • $_degree • $_branch$cgpaSummary • $_gradYear';
      default:
        return '';
    }
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

  // ── Advance ────────────────────────────────────────────────────────────────

  /// Advances to the next step. Pass [userSummary] to append a user reply
  /// bubble; omit it for steps (like skills) that already render their own
  /// bubbles in the transcript.
  void _advance({String? userSummary}) {
    final provider = context.read<OnboardingFlowProvider>();
    _commitToProvider(provider);

    final nextStep = _step + 1;
    provider.chatStep = nextStep;
    provider.saveDraft();

    // 1. User answer bubble slides in; block input.
    setState(() {
      if (userSummary != null && userSummary.isNotEmpty) {
        _msgs.add(
          _Msg(id: _msgSeq++, kind: _MsgKind.user, text: userSummary),
        );
      }
      _transitioning = true;
    });
    _scrollToBottom();

    // Last step — submit after a short pause.
    if (nextStep >= _botQuestions.length) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _step = nextStep;
          _transitioning = false;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) provider.submit();
        });
      });
      return;
    }

    // 2. Show typing indicator.
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _showTyping = true);
      _scrollToBottom();
    });

    // 3. Replace typing with bot question; advance step → input transitions.
    Future.delayed(const Duration(milliseconds: 1060), () {
      if (!mounted) return;
      setState(() {
        _showTyping = false;
        _msgs.add(
          _Msg(
            id: _msgSeq++,
            kind: _MsgKind.bot,
            text: _botQuestions[nextStep],
          ),
        );
        _step = nextStep;
        _transitioning = false;
      });
      _scrollToBottom();
    });
  }

  // ── Validate + continue ────────────────────────────────────────────────────

  void _onContinue() {
    if (_transitioning) return;
    switch (_step) {
      case 0:
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) {
          _snack('Name required', 'Please enter your full name.');
          return;
        }
        final nameParts = name.split(' ').where((p) => p.isNotEmpty).toList();
        if (nameParts.length < 2) {
          _snack(
            'Full name required',
            'Please type your first and last name (e.g. "Arjun Sharma").',
          );
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
        final college = _collegeCtrl.text.trim();
        if (college.isEmpty) {
          _snack(
            'Institution required',
            'Please enter your college / institution name.',
          );
          return;
        }
        if (_degree.isEmpty) {
          _snack('Degree required', 'Please select your degree.');
          return;
        }
        if (_branch.isEmpty) {
          _snack(
            'Field of study required',
            'Please select your field of study.',
          );
          return;
        }
        if (_gradYear.isEmpty) {
          _snack(
            'Graduation year required',
            'Please select your graduation year.',
          );
          return;
        }
        final cgpaText = _cgpaCtrl.text.trim();
        final cgpaSummary = cgpaText.isEmpty
            ? ''
            : ' • CGPA: $cgpaText/$_cgpaScale';
        _advance(
          userSummary:
              '$college • $_degree • $_branch$cgpaSummary • $_gradYear',
        );

      case 2:
        if (_skills.length < _kMinSkills) {
          _snack(
            'More skills needed',
            'Please select at least $_kMinSkills skills.',
          );
          return;
        }
        // Skills already appear as their own bubbles — no summary reply.
        _advance();

      case 3:
        _finishLocationStep();
    }
  }

  // ── Location choice ────────────────────────────────────────────────────────

  void _finishLocationStep() {
    final label = _selectedLocationLabel?.trim() ?? '';
    if (label.isEmpty) {
      _snack(
        'Location required',
        'Please select your location before continuing.',
      );
      return;
    }
    _advance(userSummary: label);
  }

  /// Skip the (final) location step: advance without a location so the profile
  /// is submitted with empty location fields. Safe — `submit()` already handles
  /// the no-location case (lat/lng default to 0.0, city/state/country empty).
  void _skipLocationStep() {
    if (_transitioning) return;
    _advance(userSummary: 'Skip for now');
  }

  Future<void> _onLocationSearchChanged(String query) async {
    if (query.trim().length < 3) {
      if (mounted) {
        setState(() {
          _locationResults.clear();
          _isSearchingLocation = false;
        });
      }
      return;
    }

    setState(() => _isSearchingLocation = true);
    try {
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'proco_app'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _locationResults
            ..clear()
            ..addAll(
              data.map((item) {
                final addr = item['address'] as Map<String, dynamic>? ?? {};
                return {
                  'display_name': item['display_name'],
                  'lat': double.parse(item['lat']),
                  'lon': double.parse(item['lon']),
                  'city':
                      addr['city'] ??
                      addr['town'] ??
                      addr['village'] ??
                      addr['county'] ??
                      '',
                  'state': addr['state'] ?? '',
                  'country': addr['country'] ?? '',
                };
              }),
            );
        });
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    } finally {
      if (mounted) setState(() => _isSearchingLocation = false);
    }
  }

  void _selectLocationResult(Map<String, dynamic> item) {
    final provider = context.read<OnboardingFlowProvider>();
    final lat = item['lat'] as double;
    final lon = item['lon'] as double;
    final display = (item['display_name'] as String?) ?? '';

    provider.setLocation(
      lat,
      lon,
      displayAddress: display,
      city: (item['city'] as String?) ?? '',
      state: (item['state'] as String?) ?? '',
      country: (item['country'] as String?) ?? '',
    );
    setState(() {
      _selectedLocationLabel = display;
      _locationSearchCtrl.text = display;
      _locationResults.clear();
    });
  }

  Future<void> _useCurrentLocation() async {
    final provider = context.read<OnboardingFlowProvider>();
    setState(() => _isFetchingCurrentLocation = true);
    try {
      final result = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromLatLng(
        result.latitude,
        result.longitude,
      );
      if (!mounted) return;

      final display = result.displayAddress ?? '';
      provider.setLocation(
        result.latitude,
        result.longitude,
        displayAddress: display,
        city: address.city,
        state: address.state,
        country: address.country,
      );
      setState(() {
        _selectedLocationLabel = display.isNotEmpty
            ? display
            : '${address.city}, ${address.state}';
      });
    } catch (e) {
      _snack('Location Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isFetchingCurrentLocation = false);
      }
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

  // ── Grad years ─────────────────────────────────────────────────────────────

  List<String> get _gradYears {
    final now = DateTime.now().year;
    return List.generate(10, (i) => (now - 2 + i).toString());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
            const LagoonAppBar(),
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
      // +1 slot for the typing indicator when active
      itemCount: _msgs.length + (_showTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        // Typing indicator occupies the last slot
        if (_showTyping && i == _msgs.length) {
          return _ChatMessage(
            key: const ValueKey('typing'),
            child: const _TypingIndicator(),
          );
        }
        final msg = _msgs[i];
        final Widget content;
        switch (msg.kind) {
          case _MsgKind.bot:
            content = _BotBubble(text: msg.text);
          case _MsgKind.user:
            content = _UserBubble(text: msg.text);
          case _MsgKind.skill:
            content = _SkillBubble(
              label: msg.text,
              onRemove: () => _removeSkill(msg.text),
            );
        }
        // The stable msg.id key ensures Flutter reuses existing states and
        // only animates newly-appended bubbles — and keeps animations correct
        // when a skill bubble is removed from the middle of the list.
        return _ChatMessage(key: ValueKey(msg.id), child: content);
      },
    );
  }

  // ── Input area ─────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: _ready ? 1.0 : 0.0,
      child: IgnorePointer(
        // Disable all taps while the bot is "replying".
        ignoring: !_ready || _transitioning,
        child: Container(
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
              // Step content: fades + slides up when step advances.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.07),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStepInput(),
                ),
              ),
              SizedBox(height: 14.h),
              // Dim the button while transitioning.
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _transitioning ? 0.45 : 1.0,
                child: _step == 3
                    ? const SizedBox.shrink()
                    : _buildContinueButton(
                        // Skills step is gated on a minimum selection.
                        enabled: _step != 2 || _skills.length >= _kMinSkills,
                      ),
              ),
            ],
          ),
        ),
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
        _InputField(
          controller: _collegeCtrl,
          hint: 'Institution / College Name',
          icon: Icons.account_balance_outlined,
        ),
        SizedBox(height: 10.h),
        _DropdownInput<String>(
          hint: 'Degree',
          icon: Icons.school_outlined,
          value: _degree.isEmpty ? null : _degree,
          items: _kDegrees,
          onChanged: (v) => setState(() => _degree = v ?? ''),
        ),
        SizedBox(height: 10.h),
        _DropdownInput<String>(
          hint: 'Field of Study / Branch',
          icon: Icons.menu_book_outlined,
          value: _branch.isEmpty ? null : _branch,
          items: _kBranches,
          onChanged: (v) => setState(() => _branch = v ?? ''),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            // "Out of" scale dropdown
            Expanded(
              flex: 2,
              child: _DropdownInput<String>(
                hint: 'Out of',
                icon: Icons.bar_chart_outlined,
                value: _cgpaScale,
                items: const ['4', '10'],
                onChanged: (v) => setState(() => _cgpaScale = v ?? '10'),
              ),
            ),
            SizedBox(width: 10.w),
            // Current CGPA value
            Expanded(
              flex: 3,
              child: _InputField(
                controller: _cgpaCtrl,
                hint: 'Current CGPA',
                icon: Icons.edit_outlined,
              ),
            ),
          ],
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
    final remaining = _kMinSkills - _skills.length;
    final met = remaining <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search instead of a wall of chips — each pick becomes a chat bubble.
        SkillSearchField(
          onSelected: _addSkill,
          alreadySelected: _skills.toList(),
          hint: 'Search and add a skill...',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(
              met ? Icons.check_circle : Icons.info_outline,
              size: 14.sp,
              color: met ? kThemeColor : Colors.grey,
            ),
            SizedBox(width: 5.w),
            Text(
              met
                  ? '${_skills.length}/$_kMaxSkills skills added'
                  : 'Pick at least $_kMinSkills skills · $remaining more',
              style: TextStyle(
                color: met ? kThemeColor : Colors.grey,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Location ───────────────────────────────────────────────────────

  Widget _buildStep3() {
    final hasSelectedLocation =
        context.watch<OnboardingFlowProvider>().hasLocation &&
        ((_selectedLocationLabel?.isNotEmpty ?? false) ||
            _locationSearchCtrl.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how you want to share location',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _ChoiceChipButton(
              label: 'Use current location',
              icon: Icons.my_location_rounded,
              selected: !_preferTypingLocation,
              onTap: () => setState(() => _preferTypingLocation = false),
            ),
            _ChoiceChipButton(
              label: 'Search location',
              icon: Icons.search,
              selected: _preferTypingLocation,
              onTap: () => setState(() => _preferTypingLocation = true),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (!_preferTypingLocation)
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton.icon(
              onPressed: _isFetchingCurrentLocation
                  ? null
                  : _useCurrentLocation,
              icon: _isFetchingCurrentLocation
                  ? const WaveLoader.small()
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                _isFetchingCurrentLocation
                    ? 'Fetching location...'
                    : 'Fetch Current Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              _InputField(
                controller: _locationSearchCtrl,
                hint: 'Search city / area',
                icon: Icons.search,
                onChanged: _onLocationSearchChanged,
              ),
              if (_isSearchingLocation) ...[
                SizedBox(height: 8.h),
                const LinearProgressIndicator(minHeight: 2, color: kThemeColor),
              ],
              if (_locationResults.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: 170.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _locationResults.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = _locationResults[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey.shade600,
                          size: 18.sp,
                        ),
                        title: Text(
                          item['display_name'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black87,
                          ),
                        ),
                        onTap: () => _selectLocationResult(item),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        if ((_selectedLocationLabel?.isNotEmpty ?? false)) ...[
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: kThemeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: kThemeColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: kThemeColor, size: 16),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _selectedLocationLabel!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: hasSelectedLocation ? _finishLocationStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kThemeColor,
              disabledBackgroundColor: kThemeColor.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Center(
          child: TextButton(
            onPressed: _skipLocationStep,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
            child: Text(
              'Skip for now',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Continue button ────────────────────────────────────────────────────────

  Widget _buildContinueButton({bool enabled = true}) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: enabled ? _onContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kThemeColor,
          disabledBackgroundColor: kThemeColor.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
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
              decoration: const BoxDecoration(
                color: _kBotBubble,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
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
              decoration: const BoxDecoration(
                color: _kUserBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
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

/// A selected-skill reply: a rounded pill on the user's side of the chat,
/// with a tap-to-remove control.
class _SkillBubble extends StatelessWidget {
  const _SkillBubble({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(width: 48.w),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.only(
                  left: 14.w,
                  right: 6.w,
                  top: 7.h,
                  bottom: 7.h,
                ),
                decoration: BoxDecoration(
                  color: kThemeColor,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.sp,
                color: selected ? Colors.white : Colors.black54,
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (selected && icon == null) ...[
              SizedBox(width: 4.w),
              const Icon(Icons.check, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;

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
              onChanged: onChanged,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade400,
                ),
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
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                ),
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                dropdownColor: Colors.white,
                items: items
                    .map(
                      (v) => DropdownMenuItem<T>(
                        value: v,
                        child: Text(v.toString()),
                      ),
                    )
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
          Icon(
            Icons.calendar_month_outlined,
            size: 16.sp,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
