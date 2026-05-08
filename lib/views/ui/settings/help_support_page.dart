import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _faqs = [
    _Faq(
      question: 'How do I create a opportunity?',
      answer:
          'Go to "My Opportunities" from the drawer, then tap the + button to post a new opportunity with details about what you\'re looking for.',
    ),
    _Faq(
      question: 'How does matching work?',
      answer:
          'When a opportunity poster swipes right on an interested applicant, it\'s a match! Both users are then able to chat with each other.',
    ),
    _Faq(
      question: 'How do I enable or disable notifications?',
      answer:
          'Go to Settings → Notifications and toggle match or chat notifications on or off.',
    ),
    _Faq(
      question: 'How do I update my profile?',
      answer:
          'Open the drawer and tap "Profile". You can edit your information, skills, and profile photo from there.',
    ),
    _Faq(
      question: 'How do I delete my account?',
      answer:
          'Go to Settings → Account → Delete Account. This action is permanent and cannot be undone.',
    ),
    _Faq(
      question: 'Why am I not receiving notifications?',
      answer:
          'Make sure notifications are enabled in Settings → Notifications and that you have granted notification permission to the app in your device settings.',
    ),
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@proco.app',
      query: 'subject=ProCo Support Request',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: const LagoonAppBar(),

      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          children: [
            SizedBox(height: 16.h),

            // ── Back Button ─────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 18.sp,
                        color: Colors.black87,
                      ),

                      SizedBox(width: 2.w),

                      Text(
                        'Back',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ── Title ───────────────────────────
            Text(
              'Help & Support',
              style: GoogleFonts.montserrat(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 6.h),

            Text(
              'Find answers to common questions and contact support.',
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                color: Colors.black45,
                height: 1.45,
              ),
            ),

            SizedBox(height: 28.h),

            // ── FAQ Label ───────────────────────
            _sectionLabel('FREQUENTLY ASKED QUESTIONS'),

            SizedBox(height: 12.h),

            ..._faqs.map((faq) => _FaqTile(faq: faq)),

            SizedBox(height: 26.h),

            // ── Contact Label ───────────────────
            _sectionLabel('CONTACT SUPPORT'),

            SizedBox(height: 12.h),

            // ── Email Support ───────────────────
            GestureDetector(
              onTap: _launchEmail,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: kThemeColor.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: kThemeColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        color: kThemeColor,
                        size: 22.sp,
                      ),
                    ),

                    SizedBox(width: 14.w),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Support',
                            style: GoogleFonts.dmSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 3.h),

                          Text(
                            'support@proco.app',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5.sp,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black26,
                      size: 15.sp,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black38,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;

  const _Faq({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;

  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: kThemeColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),

        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),

          childrenPadding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 16.h,
          ),

          onExpansionChanged: (v) {
            setState(() => _expanded = v);
          },

          trailing: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: kThemeColor,
            size: 22.sp,
          ),

          title: Text(
            widget.faq.question,
            style: GoogleFonts.dmSans(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          children: [
            Text(
              widget.faq.answer,
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
