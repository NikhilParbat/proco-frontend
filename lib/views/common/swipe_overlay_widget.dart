import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SwipeOverlayWidget extends StatelessWidget {
  final CardSwiperDirection direction;
  final IconData leftIcon;
  final String leftLabel;
  final IconData rightIcon;
  final String rightLabel;

  static const Color _red = Color(0xFFD23838);
  static const Color _green = Color(0xFF089F20);

  const SwipeOverlayWidget({
    super.key,
    required this.direction,
    required this.leftIcon,
    required this.leftLabel,
    required this.rightIcon,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = direction == CardSwiperDirection.left;
    final Color color = isLeft ? _red : _green;
    final IconData icon = isLeft ? leftIcon : rightIcon;
    final String label = isLeft ? leftLabel : rightLabel;
    final Alignment alignment = isLeft ? Alignment.topLeft : Alignment.topRight;
    final EdgeInsets padding = isLeft
        ? EdgeInsets.only(top: 30.h, left: 22.w)
        : EdgeInsets.only(top: 30.h, right: 22.w);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: color, width: 3),
        ),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: padding,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
