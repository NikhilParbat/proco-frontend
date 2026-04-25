import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';

class MatchDialog extends StatelessWidget {
  final SwipedRes user;
  final VoidCallback onGoToChat;
  final VoidCallback onBackToList;

  static const Color _accept = Color(0xFF2DB67D);
  static const Color _teal = Color(0xFF08979F);
  static const Color _navy = Color(0xFF040326);

  const MatchDialog({
    super.key,
    required this.user,
    required this.onGoToChat,
    required this.onBackToList,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _accept.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: _accept.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_rounded, color: _accept, size: 36),
            ),
            SizedBox(height: 16.h),
            Text(
              "It's a Match!",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'You matched with ${user.username}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white54,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 20.h),
            CircleAvatar(
              radius: 40.r,
              backgroundColor: _teal.withValues(alpha: 0.2),
              backgroundImage:
                  user.profile.isNotEmpty ? NetworkImage(user.profile) : null,
              child: user.profile.isEmpty
                  ? Icon(Icons.person_rounded, color: _teal, size: 36)
                  : null,
            ),
            SizedBox(height: 8.h),
            Text(
              user.username,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 24.h),
            // Go to Chat
            GestureDetector(
              onTap: onGoToChat,
              child: Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: _accept,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: _accept.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8.w),
                    Text(
                      'Message ${user.username}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Back to list
            GestureDetector(
              onTap: onBackToList,
              child: Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Center(
                  child: Text(
                    'Back to List',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
