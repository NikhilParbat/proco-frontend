import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';

/// Parallax preview card used inside the PageView carousel.
/// Tapping anywhere on the card calls [onTap] to open the swipe page.
class ParallaxUserCard extends StatelessWidget {
  final SwipedRes user;
  final double pageOffset;
  final VoidCallback onTap;

  const ParallaxUserCard({
    super.key,
    required this.user,
    required this.pageOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gaussian curve peaks when the adjacent card is half-visible,
    // producing the smooth horizontal "push" parallax translation.
    final double gauss = math.exp(
      -(math.pow((pageOffset.abs() - 0.5), 2) / 0.08),
    );

    // Headline Logic: Show Latest College + Branch
    final String headline = user.education.isNotEmpty
        ? '${user.education.first.college} • ${user.education.first.branch}'
        : 'Student';

    // Location Formatting
    final String location = (user.city.isNotEmpty && user.country.isNotEmpty)
        ? '${user.city}, ${user.country}'
        : '';

    return Transform.translate(
      offset: Offset(-32 * gauss * pageOffset.sign, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 8, right: 8, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                offset: const Offset(8, 20),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo: Top 50% section
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: user.profile.isNotEmpty
                      ? Image.network(
                          user.profile,
                          fit: BoxFit.cover,
                          alignment: Alignment(pageOffset * 0.4, 0),
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),

              // 2. Info Section: Fills the white space
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name: Large and Bold
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: kNavy,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Education: Headline
                      SizedBox(height: 2.h),
                      Text(
                        headline,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: kTeal,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Location: Small with pin icon
                      if (location.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: kThemeColor,
                              size: 14,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Bio Snippet: The "Hook"
                      if (user.bio.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Text(
                          user.bio,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                            height: 1.4,
                          ),
                          maxLines: 2, // Teaser limited to 2 lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const Spacer(),

                      // Top 3 Skills: Slightly larger chips
                      if (user.skills.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: user.skills
                              .take(3)
                              .map(_skillChip)
                              .toList(),
                        ),

                      const Spacer(),

                      // Tap hint
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 14,
                              color: kTeal.withValues(alpha: 0.5),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: kTeal.withValues(alpha: 0.5),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: kTeal.withValues(alpha: 0.10),
    child: const Center(
      child: Icon(Icons.person_rounded, color: kTeal, size: 64),
    ),
  );

  Widget _skillChip(String skill) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: kTeal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kTeal.withValues(alpha: 0.20)),
    ),
    child: Text(
      skill,
      style: TextStyle(
        fontSize: 11.sp,
        color: kTeal,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
  );
}
