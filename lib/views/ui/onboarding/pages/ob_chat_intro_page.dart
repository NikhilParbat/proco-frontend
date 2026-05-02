import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/ui/mainscreen.dart';

// ── Colours ────────────────────────────────────────────────────────────────────

const _kBotBubble = kThemeColor;
const _kUserBubble = Color.fromARGB(200, 216, 87, 87);

// ── Static data ────────────────────────────────────────────────────────────────

const _kSkills = [
  'Flutter',
  'Python',
  'Java',
  'JavaScript',
  'Node.js',
  'React',
  'Firebase',
  'SQL',
  'Product Mgmt',
  'Marketing',
  'UI/UX',
  'Machine Learning',
  'Kotlin',
  'Swift',
];

const _kDegrees = [
  'B.Tech / CSE',
  'B.Tech / ECE',
  'B.Tech / ME',
  'B.Tech / Civil',
  'B.Tech / IT',
  'B.Tech / EEE',
  'M.Tech',
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

const _kGenders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

// ── Message model ──────────────────────────────────────────────────────────────

class _Msg {
  const _Msg({required this.isBot, required this.text});
  final bool isBot;
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
  final _collegeCtrl = TextEditingController();
  String _gradYear = '';

  // Step 2: Skills
  final Set<String> _skills = {};
  final _skillSearchCtrl = TextEditingController();
  final _customSkillCtrl = TextEditingController();
  String _skillQuery = '';
  bool _showCustomSkill = false;

  static const List<String> _botQuestions = [
    "Welcome to Lagoon! 👋 Let's get the basics down.\nWhat's your Name, Gender, and Date of Birth?",
    "Great. Now, tell me about your studies.\nWhat's your Degree / Branch, College, and when do you Graduate?",
    "What are you good at? Pick your top skills so we can match you with the right projects.",
    "Last step! We need your Location to show you students and opportunities in your area.",
  ];

  @override
  void initState() {
    super.initState();
    _skillSearchCtrl.addListener(
      () => setState(
        () => _skillQuery = _skillSearchCtrl.text.trim().toLowerCase(),
      ),
    );
    // Delay first question so page transition finishes first.
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        setState(() {
          _msgs.add(const _Msg(isBot: true, text: ''));
          _ready = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _collegeCtrl.dispose();
    _skillSearchCtrl.dispose();
    _customSkillCtrl.dispose();
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

  // ── Advance ────────────────────────────────────────────────────────────────

  void _advance({required String userSummary, bool skipped = false}) {
    final provider = context.read<OnboardingFlowProvider>();

    // Persist data for current step
    if (_step == 0) {
      provider.name = _nameCtrl.text.trim();
      provider.gender = _gender;
      if (_dob != null) {
        final m = _dob!.month.toString().padLeft(2, '0');
        final d = _dob!.day.toString().padLeft(2, '0');
        provider.dob = '${_dob!.year}-$m-$d';
      }
    } else if (_step == 1) {
      provider.institution = _collegeCtrl.text.trim();
      provider.branch = _degree;
    } else if (_step == 2) {
      provider.skills = List.from(_skills);
    }

    final nextStep = _step + 1;

    // 1. User answer bubble slides in; block input.
    setState(() {
      _msgs.add(_Msg(isBot: false, text: userSummary));
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
        _msgs.add(const _Msg(isBot: true, text: ''));
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
          _snack(
            'Graduation year required',
            'Please select your graduation year.',
          );
          return;
        }
        _advance(userSummary: '$_degree, $college, $_gradYear');

      case 2:
        if (_customSkillCtrl.text.trim().isNotEmpty) {
          _addCustomSkill();
        }
        if (_skills.isEmpty) {
          _snack('Select skills', 'Pick at least one skill.');
          return;
        }
        _advance(userSummary: _skills.join(', '));

      case 3:
        _finishLocationStep(enabled: false);
    }
  }

  // ── Location choice ────────────────────────────────────────────────────────

  void _finishLocationStep({required bool enabled}) {
    _advance(
      userSummary: enabled ? 'Location access enabled' : 'Not now',
      skipped: !enabled,
    );
  }

  void _addCustomSkill() {
    final value = _customSkillCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _skills.add(value);
      _customSkillCtrl.clear();
    });
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

  void _skipToHome() =>
      Get.offAll(() => const MainScreen(), transition: Transition.fade);

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
        final content = msg.isBot
            ? _BotBubble(text: _botQuestions[i ~/ 2])
            : _UserBubble(text: msg.text);
        // ValueKey(i) ensures Flutter reuses existing states and only
        // creates a new _ChatMessageState (and triggers the animation) for
        // items appended at the end.
        return _ChatMessage(key: ValueKey(i), child: content);
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
                    : _buildContinueButton(),
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
          children: [
            ...filtered.map((s) {
              final selected = _skills.contains(s);
              return _ChoiceChipButton(
                label: s,
                selected: selected,
                onTap: () => setState(() {
                  selected ? _skills.remove(s) : _skills.add(s);
                }),
              );
            }),
            _ChoiceChipButton(
              label: 'Custom',
              icon: Icons.add,
              selected: _showCustomSkill,
              onTap: () => setState(() => _showCustomSkill = !_showCustomSkill),
            ),
          ],
        ),
        if (_showCustomSkill) ...[
          SizedBox(height: 10.h),
          _CustomOptionInput(
            controller: _customSkillCtrl,
            hint: 'Type a skill',
            onSubmitted: (_) => _addCustomSkill(),
            onAdd: _addCustomSkill,
          ),
        ],
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

  // ── Step 3: Location ───────────────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      children: [
        SizedBox(height: 4.h),
        Container(
          width: 74.w,
          height: 74.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
          ),
          child: Icon(
            Icons.location_on,
            size: 34.sp,
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(height: 28.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Add your location later from profile settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'We will skip location for now and take you to your home feed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.sp,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: () => _finishLocationStep(enabled: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: kThemeColor,
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
        SizedBox(height: 14.h),
        TextButton(
          onPressed: () => _finishLocationStep(enabled: false),
          child: Text(
            'Skip',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Continue button ────────────────────────────────────────────────────────

  Widget _buildContinueButton() {
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

class _CustomOptionInput extends StatelessWidget {
  const _CustomOptionInput({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You can type it in the chat box and send. After you are done, click Continue.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 12.sp,
            height: 1.35,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: EdgeInsets.only(left: 12.w, right: 6.w),
          child: Row(
            children: [
              Icon(Icons.add, size: 16.sp, color: kThemeColor),
              SizedBox(width: 6.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: onSubmitted,
                ),
              ),
              TextButton(
                onPressed: onAdd,
                child: Text(
                  'Send',
                  style: TextStyle(
                    color: kThemeColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;

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
