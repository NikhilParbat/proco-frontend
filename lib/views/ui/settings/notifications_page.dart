import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrefNotifMatches = 'pref_notif_matches';
const String kPrefNotifChat = 'pref_notif_chat';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);

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
    if (mounted) setState(() => _notifMatches = value);
  }

  Future<void> _setChatNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefNotifChat, value);
    if (mounted) setState(() => _notifChat = value);
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
          'Notifications',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                children: [
                  _NotifTile(
                    icon: Icons.favorite_rounded,
                    label: 'Match Notifications',
                    subtitle: 'Get notified when you are matched',
                    value: _notifMatches,
                    onChanged: _setMatchNotif,
                  ),
                  SizedBox(height: 16.h),
                  _NotifTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat Notifications',
                    subtitle: 'Get notified when you receive a message',
                    value: _notifChat,
                    onChanged: _setChatNotif,
                  ),
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

  static const Color _card = Color(0xFF0D1B2A);
  static const Color _teal = Color(0xFF08979F);

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
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
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
            child: Icon(icon, color: _teal, size: 22),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white38,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _teal,
          ),
        ],
      ),
    );
  }
}
