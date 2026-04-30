import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const Color _navy = Color(0xFF040326);
  static const Color _card = Color(0xFF0D1B2A);
  static const Color _teal = Color(0xFF08979F);

  static const _faqs = [
    _Faq(
      question: 'How do I create a query?',
      answer:
          'Go to "My Queries" from the drawer, then tap the + button to post a new query with details about what you\'re looking for.',
    ),
    _Faq(
      question: 'How does matching work?',
      answer:
          'When a query poster swipes right on an interested applicant, it\'s a match! Both users are then able to chat with each other.',
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
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          children: [
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                fontFamily: 'Poppins',
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12.h),
            ..._faqs.map((faq) => _FaqTile(faq: faq)),
            SizedBox(height: 28.h),
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                fontFamily: 'Poppins',
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: _launchEmail,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        color: _teal,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Support',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'support@proco.app',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white38,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  static const Color _card = Color(0xFF0D1B2A);
  static const Color _teal = Color(0xFF08979F);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          childrenPadding:
              EdgeInsets.only(left: 16.w, right: 16.w, bottom: 14.h),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          trailing: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: _teal,
            size: 22,
          ),
          title: Text(
            widget.faq.question,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          children: [
            Text(
              widget.faq.answer,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white60,
                fontFamily: 'Poppins',
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
