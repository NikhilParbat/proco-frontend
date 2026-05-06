import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrefProfileViewChat = 'pref_profile_view_chat';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  bool _allowProfileViewChat = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _allowProfileViewChat = prefs.getBool(kPrefProfileViewChat) ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _setAllowProfileViewChat(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefProfileViewChat, value);
    if (mounted) setState(() => _allowProfileViewChat = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: kThemeColor))
            : ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left,
                                size: 18.sp, color: Colors.black87),
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

                  Text(
                    'Profile View',
                    style: GoogleFonts.montserrat(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Control who can view your profile and when.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.sp,
                      color: Colors.black45,
                      height: 1.45,
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Toggleable
                  _ToggleTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Visible while chatting',
                    description:
                        'Allow the other person to tap your name in chat '
                        'and view your full profile.',
                    value: _allowProfileViewChat,
                    onChanged: _setAllowProfileViewChat,
                  ),

                  SizedBox(height: 24.h),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14.sp, color: Colors.black38),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Changes apply immediately. The other person can only '
                          'view your profile from chat if you have this enabled.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12.sp,
                            color: Colors.black38,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: value
            ? Border.all(
                color: kThemeColor.withValues(alpha: 0.4), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: value
                  ? kThemeColor.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: value ? kThemeColor : Colors.black38,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: kThemeColor,
            activeTrackColor: kThemeColor.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
