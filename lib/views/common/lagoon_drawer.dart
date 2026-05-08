import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/ui/bookmarks/bookmarks.dart';
import 'package:proco/views/ui/jobs/jobs_list.dart';
import 'package:proco/views/ui/notification/notification_page.dart';
import 'package:proco/views/ui/profile/profile_screen.dart';
import 'package:proco/views/ui/settings/settings_page.dart';

class LagoonDrawer extends StatelessWidget {
  const LagoonDrawer({super.key});

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
      width: 290.w,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),

              // ── Header ─────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: kThemeColor.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
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
                      child: Center(
                        child: Icon(
                          Icons.waves_rounded,
                          color: kThemeColor,
                          size: 24.sp,
                        ),
                      ),
                    ),

                    SizedBox(width: 14.w),

                    Expanded(
                      child: SvgPicture.asset(
                        'assets/Lagcon.svg',
                        height: 22.h,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // ── Navigation ─────────────────────────
              // ── Navigation ─────────────────────────
              _item(
                context,
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () => _navigate(context),
              ),

              _item(
                context,
                icon: Icons.bookmark_border_rounded,
                label: 'Bookmarks',
                onTap: () => _navigate(context, page: const BookMarkPage()),
              ),

              _item(
                context,
                icon: Icons.work_outline_rounded,
                label: 'My Opportunities',
                onTap: () => _navigate(context, page: const JobListPage()),
              ),

              _item(
                context,
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => _navigate(context, page: const NotificationPage()),
              ),

              _item(
                context,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () => _navigate(context, page: const ProfilePage()),
              ),

              _item(
                context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => _navigate(context, page: const SettingsPage()),
              ),

              const Spacer(),

              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = kThemeColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, color: color, size: 21.sp),
                ),

                SizedBox(width: 14.w),

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: kFontDMSans,
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black26,
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
