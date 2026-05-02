import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proco/views/ui/bookmarks/bookmarks.dart';
import 'package:proco/views/ui/jobs/jobs_list.dart';
import 'package:proco/views/ui/notification/notification_page.dart';
import 'package:proco/views/ui/profile/profile_screen.dart';
import 'package:proco/views/ui/settings/settings_page.dart';

class LagoonDrawer extends StatelessWidget {
  const LagoonDrawer({super.key});

  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);

  void _navigate(BuildContext context, {Widget? page}) {
    Navigator.pop(context);
    Navigator.popUntil(context, (route) => route.isFirst);
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(13.w, 18.h, 13.w, 14.h),
              child: SvgPicture.asset(
                'assets/Lagcon.svg',
                width: 100.w,
                height: 26.h,
                fit: BoxFit.contain,
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            SizedBox(height: 9.h),
            _item(
              context,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => _navigate(context),
            ),
            _item(
              context,
              icon: Icons.bookmark_rounded,
              label: 'Bookmarks',
              onTap: () => _navigate(context, page: const BookMarkPage()),
            ),
            _item(
              context,
              icon: Icons.list_alt_rounded,
              label: 'List Query',
              onTap: () => _navigate(context, page: const JobListPage()),
            ),
            _item(
              context,
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              onTap: () => _navigate(context, page: const NotificationPage()),
            ),
            _item(
              context,
              icon: Icons.person_rounded,
              label: 'Profile',
              // 2. REMOVE 'const' HERE
              onTap: () => _navigate(context, page: const ProfilePage()),
            ),
            _item(
              context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () => _navigate(context, page: const SettingsPage()),
            ),
            const Spacer(),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            _item(
              context,
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: const Color(0xFFf55631),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 14.h),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _teal,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      onTap: onTap,
    );
  }
}
