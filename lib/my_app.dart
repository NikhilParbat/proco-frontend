import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool onboardingComplete;
  final int onboardingPage;
  final SharedPreferences prefs;

  final bool isPendingVerification;
  final String pendingEmail;
  final String pendingUsername;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.onboardingComplete,
    required this.onboardingPage,
    required this.prefs,
    this.isPendingVerification = false,
    this.pendingEmail = '',
    this.pendingUsername = '',
  });

  Widget get _home {
    if (!isLoggedIn) {
      return const LoginPage(drawer: false);
    }

    if (!onboardingComplete) {
      return OnboardingFlow(initialPage: onboardingPage);
    }

    return MainScreen(prefs: prefs);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 825),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lagoon',
          theme: ThemeData(
            scaffoldBackgroundColor: kBackgroundColor,
            iconTheme: const IconThemeData(color: kDark),
            primarySwatch: Colors.grey,
          ),

          // Direct screen rendering
          home: _home,
        );
      },
    );
  }
}
