import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/ui/device_mgt/devices_info.dart';
import 'package:proco/views/ui/settings/account_page.dart';
import 'package:proco/views/ui/settings/help_support_page.dart';
import 'package:proco/views/ui/settings/notifications_page.dart';
import 'package:proco/views/ui/settings/profile_view_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
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

            SizedBox(height: 14.h),

            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              subtitle: 'Manage match and chat notification preferences',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),

            SizedBox(height: 14.h),

            _SettingsTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              subtitle: 'FAQs and contact support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage()),
              ),
            ),

            SizedBox(height: 14.h),

            _SettingsTile(
              icon: Icons.visibility_outlined,
              label: 'Profile View',
              subtitle: 'Control who can view your profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileViewPage()),
              ),
            ),

            SizedBox(height: 14.h),

            _SettingsTile(
              icon: Icons.person_outline_rounded,
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

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: kThemeColor.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Icon ─────────────────────────────
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: kThemeColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: kBackgroundColor, size: 22.sp),
              ),

              SizedBox(width: 14.w),

              // ── Text ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        fontFamily: kFontDMSans,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Colors.grey.shade600,
                        fontFamily: kFontDMSans,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Arrow ────────────────────────────
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.black26,
                size: 15.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
