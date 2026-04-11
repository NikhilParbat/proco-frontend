import 'package:flutter/material.dart';
import 'package:proco/views/common/custom_outline_btn.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/common/height_spacer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DevicesInfo extends StatelessWidget {
  const DevicesInfo({
    this.location,
    required this.device,
    required this.platform,
    required this.date,
    this.ipAddress,
    this.onSignOut,
    super.key,
  });

  final String? location;
  final String device;
  final String platform;
  final String date;
  final String? ipAddress;
  final VoidCallback? onSignOut;

  static const Color _navy = Color(0xFF040326);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReusableText(
            text: platform,
            style: appstyle(22, Colors.white, FontWeight.bold),
          ),
          ReusableText(
            text: device,
            style: appstyle(22, Colors.white, FontWeight.bold),
          ),
          const HeightSpacer(size: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableText(
                    text: date,
                    style: appstyle(16, kDarkGrey, FontWeight.w400),
                  ),
                  ReusableText(
                    text: ipAddress != null
                        ? "IP: $ipAddress"
                        : "IP Address not available",
                    style: appstyle(16, kDarkGrey, FontWeight.w400),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onSignOut,
                child: CustomOutlineBtn(
                  text: 'Sign Out',
                  color: kTeal,
                  height: height * 0.05,
                  width: width * 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
