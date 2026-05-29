import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_colors.dart';

// Fonts
const String kFontMontserrat = 'Montserrat';
const String kFontDMSans = 'DMSans';

// Headings
TextStyle get kHeadingStyle => TextStyle(
  fontFamily: kFontMontserrat,
  fontSize: 25.sp,
  fontWeight: FontWeight.w700,
  color: kDark,
);

TextStyle get kTitleStyle => TextStyle(
  fontFamily: kFontMontserrat,
  fontSize: 20.sp,
  fontWeight: FontWeight.w700,
  color: kDark,
);

// Text
TextStyle get kSubTextStyle => TextStyle(
  fontFamily: kFontDMSans,
  fontSize: 16.sp,
  fontWeight: FontWeight.w500,
  color: const Color(0xFF141414),
);

TextStyle get kBodyStyle => TextStyle(
  fontFamily: kFontDMSans,
  fontSize: 15.sp,
  fontWeight: FontWeight.w400,
  color: kDark,
);

TextStyle get kSmallTextStyle => TextStyle(
  fontFamily: kFontDMSans,
  fontSize: 14.sp,
  fontWeight: FontWeight.w400,
  color: kDarkGrey,
);

TextStyle get kCaptionStyle => TextStyle(
  fontFamily: kFontDMSans,
  fontSize: 12.sp,
  fontWeight: FontWeight.w500,
  color: kDarkGrey,
);

// Extra commonly-used styles
TextStyle get kSectionTitleStyle => TextStyle(
  fontFamily: kFontMontserrat,
  fontSize: 18.sp,
  fontWeight: FontWeight.w700,
  color: kDark,
);

TextStyle get kButtonTextStyle => TextStyle(
  fontFamily: kFontDMSans,
  fontSize: 14.sp,
  fontWeight: FontWeight.w600,
  color: kLight,
);
