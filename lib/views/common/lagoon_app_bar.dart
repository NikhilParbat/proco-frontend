import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:proco/views/common/exports.dart';

class LagoonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LagoonAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(50.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 50.h,
      leadingWidth: 170.w,
      leading: Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.waves_rounded, color: kThemeColor, size: 28.sp),

                SizedBox(width: 8.w),
                SvgPicture.asset(
                  'assets/Lagoon.svg',
                  width: 80.w,
                  height: 26.h,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}
