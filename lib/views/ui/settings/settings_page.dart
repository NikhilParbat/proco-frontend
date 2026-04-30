import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/drawer/drawer_widget.dart';
import 'package:proco/views/ui/device_mgt/devices_info.dart';
import 'package:proco/views/ui/settings/account_page.dart';
import 'package:proco/views/ui/settings/help_support_page.dart';
import 'package:proco/views/ui/settings/notifications_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color _navy = Color(0xFF040326);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.065.sh),
        child: CustomAppBar(
          text: 'Settings',
          child: Padding(
            padding: EdgeInsets.only(left: 0.010.sh),
            child: const DrawerWidget(),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          children: [
            _SettingsTile(
              icon: MaterialCommunityIcons.devices,
              label: 'Device Management',
              subtitle: 'View and manage your logged-in devices',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceManagement()),
              ),
            ),
            SizedBox(height: 16.h),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              subtitle: 'Manage match and chat notification preferences',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
            SizedBox(height: 16.h),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              subtitle: 'FAQs and contact support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage()),
              ),
            ),
            SizedBox(height: 16.h),
            _SettingsTile(
              icon: Icons.person_rounded,
              label: 'Account',
              subtitle: 'Manage your account settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _card = Color(0xFF0D1B2A);
  static const Color _teal = Color(0xFF08979F);

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
