import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';

/// Bottom info section of a parallax preview card.
/// No action buttons — the card itself is tappable to open the swipe page.
class UserCardContent extends StatelessWidget {
  final SwipedRes user;

  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _orange = Color(0xFFf55631);

  const UserCardContent({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            user.username,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: _navy,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Location
          if (user.location.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: _orange, size: 13),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    user.location,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Skills
          if (user.skills.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: user.skills.take(3).map(_skillChip).toList(),
            ),
          ],

          const Spacer(),

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 14, color: _teal.withValues(alpha: 0.5)),
              SizedBox(width: 4.w),
              Text(
                'Tap to view',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _teal.withValues(alpha: 0.5),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String skill) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _teal.withValues(alpha: 0.25)),
        ),
        child: Text(
          skill,
          style: TextStyle(
            fontSize: 11.sp,
            color: _teal,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      );
}
