import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/settings_page_header.dart';
import 'package:proco/views/common/wave_loader.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const Color _red = Color(0xFFD23838);

  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),

        title: Text(
          'Delete Account',
          style: GoogleFonts.dmSans(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.dmSans(
            fontSize: 13.sp,
            color: Colors.black54,
            height: 1.5,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: _red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    final response = await UserHelper.deleteAccount();

    if (!mounted) return;

    setState(() => _deleting = false);

    if (response.success) {
      context.read<LoginNotifier>().logout();
    } else {
      Get.snackbar(
        'Error',
        response.message,
        backgroundColor: _red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
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

            SettingsPageHeader(
              title: 'Account',
              subtitle: 'Manage your Lagoon account settings and preferences.',
            ),

            // ── Danger Zone Label ───────────────
            _sectionLabel('DANGER ZONE'),

            SizedBox(height: 12.h),

            // ── Delete Account Tile ─────────────
            GestureDetector(
              onTap: _deleting ? null : _confirmDelete,

              child: Container(
                padding: EdgeInsets.all(16.w),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),

                  border: Border.all(color: _red.withValues(alpha: 0.12)),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    // ── Icon ───────────────────────
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14.r),
                      ),

                      child: _deleting
                          ? Padding(
                              padding: EdgeInsets.all(11.r),
                              child: const WaveLoader.small(),
                            )
                          : Icon(
                              Icons.delete_outline_rounded,
                              color: _red,
                              size: 22.sp,
                            ),
                    ),

                    SizedBox(width: 14.w),

                    // ── Text ───────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Account',
                            style: GoogleFonts.dmSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _red,
                            ),
                          ),

                          SizedBox(height: 3.h),

                          Text(
                            'Permanently remove your account and all associated data.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5.sp,
                              color: Colors.black45,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _red.withValues(alpha: 0.4),
                      size: 15.sp,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // ── Footer Info ────────────────────
            SettingsInfoFooter(
              message:
                  'Deleting your account is permanent and cannot be undone.',
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
