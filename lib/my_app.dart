import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Target width for the mobile-frame on desktop browsers.
/// ScreenUtilInit reads the raw FlutterView size (bypassing MediaQuery
/// widgets), so we override ScreenUtil.configure() inside
/// GetMaterialApp.builder — which runs AFTER ScreenUtilInit but BEFORE
/// any page widget builds.  This forces all .w / .h / .sp to scale
/// against 430 px instead of the full browser viewport.
const double _kMobileWidth = 430.0;
const Color _kWebBg = Color(0xFF1A1A2E);

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
          // On wide-screen browsers: re-configure ScreenUtil to 430 px and
          // visually centre the app in a phone-width column.
          builder: kIsWeb ? _webAppBuilder : null,
          home: _home,
        );
      },
    );
  }
}

/// GetMaterialApp.builder runs during the parent build pass, before any
/// route/page widget builds.  Calling ScreenUtil.configure() here
/// overrides the scale factor set by ScreenUtilInit (which used the raw
/// FlutterView width) so that all subsequent .w/.h/.sp reads use 430 px.
Widget _webAppBuilder(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);

  // Mobile browsers (≤430 px) — no override needed
  if (mq.size.width <= _kMobileWidth) {
    return child ?? const SizedBox();
  }

  // Desktop / tablet browser: force ScreenUtil to scale against 430 px
  ScreenUtil.configure(
    data: mq.copyWith(size: Size(_kMobileWidth, mq.size.height)),
    designSize: const Size(375, 825),
    splitScreenMode: false,
    minTextAdapt: true,
  );

  return ColoredBox(
    color: _kWebBg,
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _kMobileWidth,
        height: mq.size.height,
        child: child,
      ),
    ),
  );
}
