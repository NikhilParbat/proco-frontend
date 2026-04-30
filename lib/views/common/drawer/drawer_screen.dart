import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/zoom_provider.dart';
import 'package:proco/views/common/app_style.dart';
import 'package:proco/views/common/reusable_text.dart';
import 'package:proco/views/common/width_spacer.dart';
import 'package:provider/provider.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({
    required this.indexSetter,
    required this.controller,
    super.key,
  });
  final ValueSetter indexSetter;
  final ZoomDrawerController controller;

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ZoomNotifier>(
      builder: (context, zoomNotifier, child) {
        return GestureDetector(
          onTap: () {
            widget.controller.toggle!();
          },
          child: Scaffold(
            backgroundColor: kTeal,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                drawerItem(
                  AntDesign.home,
                  'Home',
                  0,
                  zoomNotifier.currentIndex == 0
                      ? kLight
                      : kLightGrey,
                ),
                drawerItem(
                  Ionicons.chatbubble_outline,
                  'Chat',
                  1,
                  zoomNotifier.currentIndex == 1
                      ? kLight
                      : kLightGrey,
                ),
                drawerItem(
                  Fontisto.bookmark,
                  'Saved Queries',
                  2,
                  zoomNotifier.currentIndex == 2
                      ? kLight
                      : kLightGrey,
                ),
                drawerItem(
                  Icons.settings_rounded,
                  'Settings',
                  3,
                  zoomNotifier.currentIndex == 3
                      ? kLight
                      : kLightGrey,
                ),
                drawerItem(
                  FontAwesome5Regular.clipboard,
                  'My Queries',
                  4,
                  zoomNotifier.currentIndex == 4
                      ? kLight
                      : kLightGrey,
                ),
                drawerItem(
                  FontAwesome5Regular.user_circle,
                  'Profile',
                  5,
                  zoomNotifier.currentIndex == 5
                      ? kLight
                      : kLightGrey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget drawerItem(IconData icon, String text, int index, Color color) {
    return GestureDetector(
      onTap: () {
        widget.controller.close!();
        widget.indexSetter(index);
      },
      child: Container(
        margin: EdgeInsets.only(left: 20.w, bottom: 40.h),
        child: Row(
          children: [
            Icon(icon, color: color),
            const WidthSpacer(width: 12),
            ReusableText(
              text: text,
              style: appstyle(12, color, FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
