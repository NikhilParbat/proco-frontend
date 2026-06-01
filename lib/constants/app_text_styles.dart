import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_colors.dart';

// Fonts
const String kFontMontserrat = 'Montserrat';
const String kFontDMSans = 'DMSans';

// Headings
TextStyle get kHeadingStyle => GoogleFonts.montserrat(
  fontSize: 25.sp,
  fontWeight: FontWeight.w700,
  color: kDark,
);

TextStyle get kTitleStyle => GoogleFonts.montserrat(
  fontSize: 20.sp,
  fontWeight: FontWeight.w700,
  color: kDark,
);

// Text
TextStyle get kSubTextStyle => GoogleFonts.dmSans(
  fontSize: 16.sp,
  fontWeight: FontWeight.w500,
  color: const Color(0xFF141414),
);

TextStyle get kBodyStyle => GoogleFonts.dmSans(
  fontSize: 15.sp,
  fontWeight: FontWeight.w400,
  color: kDark,
);

TextStyle get kSmallTextStyle => GoogleFonts.dmSans(
  fontSize: 14.sp,
  fontWeight: FontWeight.w400,
  color: kDarkGrey,
);

TextStyle get kCaptionStyle => GoogleFonts.dmSans(
  fontSize: 12.sp,
  fontWeight: FontWeight.w500,
  color: kDarkGrey,
);

// Extra commonly-used styles
TextStyle get kSectionTitleStyle => GoogleFonts.montserrat(
  fontSize: 18.sp,
  fontWeight: FontWeight.w700,
  color: kDark,
);

TextStyle get kButtonTextStyle => GoogleFonts.dmSans(
  fontSize: 14.sp,
  fontWeight: FontWeight.w600,
  color: kLight,
);
