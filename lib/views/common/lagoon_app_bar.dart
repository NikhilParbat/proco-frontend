import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:proco/constants/app_colors.dart';

class LagoonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LagoonAppBar({super.key, this.actions, this.showDrawer = true});

  final List<Widget>? actions;
  final bool showDrawer;

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
          onTap: showDrawer ? () => Scaffold.of(ctx).openDrawer() : null,
          child: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (showDrawer) ...[
                  Icon(Icons.waves_rounded, color: kThemeColor, size: 28.sp),
                  SizedBox(width: 8.w),
                ],
                if (kIsWeb)
                  Image.asset(
                    'assets/Lagoon.png',
                    width: 80.w,
                    height: 26.h,
                    fit: BoxFit.contain,
                  )
                else
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
