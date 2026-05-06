import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  bool _showAppSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_splashRemoved && mounted) {
        FlutterNativeSplash.remove();
        _splashRemoved = true;
      }
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() => _showAppSplash = false);
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
          home: _showAppSplash ? const _BrandSplashScreen() : _home,
        );
      },
    );
  }
}

class _BrandSplashScreen extends StatelessWidget {
  const _BrandSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD85757),
      body: Center(child: SvgPicture.asset('assets/WLagcon.svg', width: 190.w)),
    );
  }
}
