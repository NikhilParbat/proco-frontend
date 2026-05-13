import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsInfoFooter extends StatelessWidget {
  final String message;

  const SettingsInfoFooter({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14.sp, color: Colors.black38),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              color: Colors.black38,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SettingsPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 18.sp, color: Colors.black87),
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
          title,
          style: GoogleFonts.montserrat(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 13.sp,
            color: Colors.black45,
            height: 1.45,
          ),
        ),
        SizedBox(height: 28.h),
      ],
    );
  }
}
