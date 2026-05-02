import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:proco/views/ui/onboarding/onboarding_screen.dart';
import 'package:proco/views/common/exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool onboardingComplete;
  final int onboardingPage;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.onboardingComplete,
    required this.onboardingPage,
    required this.prefs,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_splashRemoved && mounted) {
        FlutterNativeSplash.remove();
        _splashRemoved = true;
      }
    });
  }

  Widget get _home {
    if (!widget.isLoggedIn) return const OnBoardingScreen();
    if (!widget.onboardingComplete) {
      return OnboardingFlow(initialPage: widget.onboardingPage);
    }
    return MainScreen(prefs: widget.prefs); // ✅ Pass prefs
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 825),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ProCo',
          theme: ThemeData(
            // CHANGE THIS LINE:
            scaffoldBackgroundColor: kBackgroundColor,

            iconTheme: const IconThemeData(color: kDark),
            primarySwatch: Colors.grey,
          ),
          home: _home,
        );
      },
    );
  }
}
