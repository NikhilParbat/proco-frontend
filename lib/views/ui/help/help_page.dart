import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/drawer/drawer_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF040326);
  static const Color _card = Color(0xFF08979F);
  static const Color _accent = Color(0xFF0BBFCA);
  static const Color _white = Colors.white;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _expandedIndex;
  bool _isSending = false;

  static const String _supportEmail = 'proco.dev01@gmail.com';

  final List<_FaqItem> _faqs = const [
    _FaqItem(
      icon: Feather.info,
      question: 'What is Lagoon and what is it used for?',
      answer:
          'Lagoon is a smart networking platform that connects students based on their skills and interests. Whether you want to join a competition, collaborate on a project, conduct research, or find freelance gigs and internships, Lagoon finds the right teammates for you.',
    ),
    _FaqItem(
      icon: Feather.shuffle,
      question: 'What does swiping left or right mean?',
      answer:
          'Swipe RIGHT on an opportunity or a person to express interest. Swipe LEFT to pass. If both parties swipe right on each other, a match is formed and you can start collaborating immediately.',
    ),
    _FaqItem(
      icon: Feather.plus_circle,
      question: 'How do I create an opportunity?',
      answer:
          'Tap the "+" button on the My Opportunities tab. Fill in the details and select a category: Competition, Collaboration, Research, Freelance, or Internship. Once posted, Lagoon will surface it to relevant users.',
    ),
    _FaqItem(
      icon: Feather.filter,
      question: 'How do I find specific types of work?',
      answer:
          'Use the Filters menu in the discovery stack. You can toggle between Competitions, Collaborations, Research, Freelance, and Internships to see only the opportunities that match your current goals.',
    ),
    _FaqItem(
      icon: Feather.eye_off,
      question: 'Can I hide my profile temporarily?',
      answer:
          'Yes. If you’ve found a team or want to take a break, go to Settings and toggle your "Discoverability" off. This hides your profile from the swipe stack until you are ready to connect again.',
    ),
    _FaqItem(
      icon: Feather.user_check,
      question: 'How do I improve my match quality?',
      answer:
          'Complete every section of your profile—add your technical skills, list your interests, and link your portfolio. The algorithm prioritizes profile completeness, so a detailed profile leads to more relevant matches.',
    ),
    _FaqItem(
      icon: Feather.message_circle,
      question: 'How do I communicate with a match?',
      answer:
          'Once a mutual match is established, a chat thread opens automatically. You can discuss project details, share resources, and plan your collaboration directly inside the Lagoon messaging screen.',
    ),
    _FaqItem(
      icon: Feather.shield,
      question: 'Is Lagoon free to use?',
      answer:
          'Yes, Lagoon is currently completely free for all students. You have full access to posting opportunities, swiping, and messaging at no cost.',
    ),
  ];
  @override
  void dispose() {
    _subjectController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final subject = Uri.encodeComponent(_subjectController.text.trim());
    final body = Uri.encodeComponent(_queryController.text.trim());
    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _subjectController.clear();
        _queryController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _card,
              content: const Text(
                'Opening mail client…',
                style: TextStyle(color: _white),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        throw 'Could not launch mail client';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Could not open mail app. Please email us at $_supportEmail',
              style: const TextStyle(color: _white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.065.sh),
        child: CustomAppBar(
          text: 'Help & Support',
          child: Padding(
            padding: EdgeInsets.only(left: 0.010.sh),
            child: const DrawerWidget(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            _buildHeroBanner(),
            SizedBox(height: 28.h),

            // FAQ section
            _sectionLabel('Frequently Asked Questions'),
            SizedBox(height: 14.h),
            ..._faqs.asMap().entries.map((e) => _buildFaqTile(e.key, e.value)),
            SizedBox(height: 28.h),

            // Contact support section
            _sectionLabel('Contact Support'),
            SizedBox(height: 14.h),
            _buildContactForm(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _card.withValues(alpha: 0.35),
            _accent.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _card.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Feather.life_buoy, color: _accent, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re here to help',
                  style: TextStyle(
                    color: _white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Browse FAQs below or send us a message and we\'ll get back to you quickly.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(int index, _FaqItem item) {
    final isExpanded = _expandedIndex == index;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isExpanded
              ? _card.withValues(alpha: 0.28)
              : _card.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? _accent.withValues(alpha: 0.6)
                : _card.withValues(alpha: 0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                _expandedIndex = isExpanded ? null : index;
              }),
              splashColor: _accent.withValues(alpha: 0.08),
              highlightColor: _accent.withValues(alpha: 0.04),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, color: _accent, size: 18.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            item.question,
                            style: TextStyle(
                              color: _white,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Feather.chevron_down,
                            color: _accent,
                            size: 18.sp,
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: EdgeInsets.only(top: 12.h, left: 28.w),
                        child: Text(
                          item.answer,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _card.withValues(alpha: 0.35)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Feather.mail, color: _accent, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Send us a message',
                  style: TextStyle(
                    color: _white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'We\'ll respond to $_supportEmail',
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
            SizedBox(height: 18.h),

            // Subject
            _buildInputLabel('Subject'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller: _subjectController,
              hint: 'e.g. Problem with matching',
              maxLines: 1,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Subject is required'
                  : null,
            ),
            SizedBox(height: 14.h),

            // opportunity
            _buildInputLabel('Your opportunity'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller: _queryController,
              hint: 'Describe your issue or question in detail…',
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'opportunity cannot be empty'
                  : null,
            ),
            SizedBox(height: 20.h),

            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _card,
                  foregroundColor: _white,
                  disabledBackgroundColor: _card.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: _isSending
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          color: _white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Feather.send, size: 16.sp),
                label: Text(
                  _isSending ? 'Opening…' : 'Send Message',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white60,
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: _white, fontSize: 13.5.sp),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        filled: true,
        fillColor: _card.withValues(alpha: 0.18),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _card.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }

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
}

// ─── Data model ────────────────────────────────────────────────────────────────

class _FaqItem {
  final IconData icon;
  final String question;
  final String answer;
  const _FaqItem({
    required this.icon,
    required this.question,
    required this.answer,
  });
}
