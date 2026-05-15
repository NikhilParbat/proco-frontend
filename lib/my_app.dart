import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:proco/views/ui/auth/login.dart';
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
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  void _handleStartup() async {
    if (!kIsWeb) FlutterNativeSplash.remove();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Get.offAll(
        () => _home,
        transition: Transition.fade,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget get _home {
    if (!widget.isLoggedIn) {
      return const LoginPage(drawer: false);
    }
    if (!widget.onboardingComplete) {
      return OnboardingFlow(initialPage: widget.onboardingPage);
    }
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
          home: const _BrandSplashScreen(),
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
