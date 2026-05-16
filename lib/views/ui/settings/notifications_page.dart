import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/settings_page_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrefNotifMatches = 'pref_notif_matches';
const String kPrefNotifChat = 'pref_notif_chat';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _notifMatches = true;
  bool _notifChat = true;
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
        _notifMatches = prefs.getBool(kPrefNotifMatches) ?? true;
        _notifChat = prefs.getBool(kPrefNotifChat) ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _setMatchNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefNotifMatches, value);

    if (mounted) {
      setState(() => _notifMatches = value);
    }
  }

  Future<void> _setChatNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefNotifChat, value);

    if (mounted) {
      setState(() => _notifChat = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: const LagoonAppBar(),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kThemeColor))
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  SizedBox(height: 16.h),

                  SettingsPageHeader(
                    title: 'Notifications',
                    subtitle: 'Manage your Lagoon notification preferences.',
                  ),

                  // ── Match Notifications ────────────
                  _NotifTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Match Notifications',
                    subtitle: 'Get notified when you are matched',
                    value: _notifMatches,
                    onChanged: _setMatchNotif,
                  ),

                  SizedBox(height: 14.h),

                  // ── Chat Notifications ─────────────
                  _NotifTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat Notifications',
                    subtitle: 'Get notified when you receive a message',
                    value: _notifChat,
                    onChanged: _setChatNotif,
                  ),

                  SizedBox(height: 24.h),

                  // ── Footer Info ────────────────────
                  SettingsInfoFooter(
                    message: 'You can update these preferences anytime from settings.',
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: kThemeColor.withValues(alpha:0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ── Icon ────────────────────────────────
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: kThemeColor.withValues(alpha:0.10),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, size: 22.sp, color: kThemeColor),
          ),

          SizedBox(width: 14.w),

          // ── Text ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 3.h),

                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5.sp,
                    color: Colors.black45,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          // ── Switch ──────────────────────────────
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: kThemeColor,
              activeTrackColor: kThemeColor.withValues(alpha:0.35),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}
