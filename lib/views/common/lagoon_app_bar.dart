import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proco/views/common/exports.dart'; // Ensure your constants are imported

class LagoonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LagoonAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(50.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Changed background color to kThemeColor as requested
      backgroundColor: kThemeColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 50.h,
      leadingWidth: 100.w,
      leading: Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'assets/WLagcon.svg',
                width: 80.w,
                height: 26.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}
