import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:proco/views/ui/auth/login.dart'; // Ensure this path matches your filename
import 'package:proco/views/ui/auth/signup_new.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:proco/views/common/exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatefulWidget {
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

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showAppSplash = true;

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  void _handleStartup() async {
    // Remove Native Splash immediately so the app can draw
    FlutterNativeSplash.remove();

    // Keep custom splash for a moment for a smooth transition
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _showAppSplash = false);
    }
  }

  Widget get _home {
    // 1. If not logged in, go directly to Login
    if (!widget.isLoggedIn) {
      return const LoginPage(drawer: false);
    }

    // 2. If logged in but profile onboarding is incomplete
    if (!widget.onboardingComplete) {
      return OnboardingFlow(initialPage: widget.onboardingPage);
    }

    // 3. Fully logged in and onboarded
    return MainScreen(prefs: widget.prefs);
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
      body: Center(
        child: SvgPicture.asset(
          'assets/WLagcon.svg',
          width: 190.w,
          placeholderBuilder: (context) =>
              const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
