import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/app_initializer.dart';
import 'package:proco/firebase_options.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/onboarding/onboarding_flow.dart';
import 'package:proco/views/ui/onboarding/onboarding_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Must be a top-level function — called when app is in background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // OS will display the notification automatically — nothing else needed here
}

Widget defaultHome = const OnBoardingScreen();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only critical init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const AppInitializer());
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool onboardingComplete;
  final int onboardingPage;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.onboardingComplete,
    required this.onboardingPage,
  });

  Widget get _home {
    if (!isLoggedIn) return const OnBoardingScreen();
    if (!onboardingComplete) {
      return OnboardingFlow(initialPage: onboardingPage);
    }
    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      useInheritedMediaQuery: true,
      designSize: const Size(375, 825),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ProCo',
          theme: ThemeData(
            scaffoldBackgroundColor: kLight,
            iconTheme: IconThemeData(color: kDark),
            primarySwatch: Colors.grey,
          ),
          home: _home,
          onInit: () => FlutterNativeSplash.remove(),
        );
      },
    );
  }
}
