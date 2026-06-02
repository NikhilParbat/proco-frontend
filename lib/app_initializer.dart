import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:proco/services/helpers/auth_helper.dart';
import 'package:proco/brand_splash_screen.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/chat_provider.dart';
import 'package:proco/controllers/filter_provider.dart';
import 'package:proco/controllers/image_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/controllers/login_provider.dart';
import 'package:proco/controllers/onboarding_provider.dart';
import 'package:proco/controllers/profile_provider.dart';
import 'package:proco/controllers/signup_provider.dart';
import 'package:proco/controllers/zoom_provider.dart';
import 'package:proco/my_app.dart';
import 'package:proco/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<_AppInitData> _initFuture;

  @override
  void initState() {
    super.initState();
    // Start initialization immediately, non-blocking
    _initFuture = _initializeApp();
  }

  /// Fast initialization - only reads from disk (SharedPreferences)
  /// Heavy async work (Firebase, dotenv) happens in background
  Future<_AppInitData> _initializeApp() async {
    try {
      // ✅ FAST: Read from local storage only
      final prefs = await SharedPreferences.getInstance();

      // On mobile, check for token in SharedPreferences
      // On web, check Firebase auth state (HttpOnly cookies handled by browser)
      bool isLoggedIn = false;
      if (kIsWeb) {
        // The web JWT lives in an HttpOnly cookie that JavaScript cannot read,
        // so we ask the backend whether the cookie is still valid. A logged-in
        // user therefore stays logged in across refreshes until they explicitly
        // log out (or the 21-day token expires).
        final sessionUserId = await AuthHelper.fetchSessionUserId();
        isLoggedIn = sessionUserId != null;
      } else {
        final token = prefs.getString('token');
        isLoggedIn = token != null && token.isNotEmpty;
      }

      final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
      final onboardingPage = prefs.getInt('onboardingPage') ?? 0;

      // ✅ Check pending verification (if not logged in)
      bool isPendingVerification = false;
      String pendingEmail = '';
      String pendingUsername = '';

      if (!isLoggedIn) {
        final savedEmail = prefs.getString('pendingVerificationEmail') ?? '';
        if (savedEmail.isNotEmpty) {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null &&
              fbUser.email == savedEmail &&
              !fbUser.emailVerified) {
            isPendingVerification = true;
            pendingEmail = savedEmail;
            pendingUsername =
                prefs.getString('pendingVerificationUsername') ?? '';
          }
        }
      }

      return _AppInitData(
        prefs: prefs,
        isLoggedIn: isLoggedIn,
        onboardingComplete: onboardingComplete,
        onboardingPage: onboardingPage,
        isPendingVerification: isPendingVerification,
        pendingEmail: pendingEmail,
        pendingUsername: pendingUsername,
      );
    } catch (e) {
      debugPrint('AppInitializer error: $e');
      // Return fallback data
      return _AppInitData(
        prefs: await SharedPreferences.getInstance(),
        isLoggedIn: false,
        onboardingComplete: false,
        onboardingPage: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppInitData>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: BrandSplashScreen(),
          );
        }

        final data = snapshot.data!;

        // ✅ Heavy initialization in background (non-blocking)
        _initializeInBackground();

        return MultiProvider(
          providers: [
            // ✅ Core providers - always needed immediately
            ChangeNotifierProvider(create: (_) => ZoomNotifier()),
            ChangeNotifierProvider(create: (_) => LoginNotifier()),

            // ✅ Lazy providers - only created when first accessed
            ChangeNotifierProvider(
              create: (_) => OnBoardNotifier(),
              lazy: true,
            ),
            ChangeNotifierProvider(create: (_) => SignUpNotifier(), lazy: true),
            ChangeNotifierProvider(create: (_) => ImageNotifier(), lazy: true),

            // ✅ Super lazy providers - depend on login state
            ChangeNotifierProxyProvider<LoginNotifier, JobsNotifier>(
              create: (_) => JobsNotifier(),
              update: (_, login, prev) => prev ?? JobsNotifier(),
              lazy: true,
            ),
            ChangeNotifierProxyProvider<LoginNotifier, BookMarkNotifier>(
              create: (_) => BookMarkNotifier(),
              update: (_, login, prev) => prev ?? BookMarkNotifier(),
              lazy: true,
            ),
            ChangeNotifierProxyProvider<LoginNotifier, ProfileNotifier>(
              create: (_) => ProfileNotifier(),
              update: (_, login, prev) => prev ?? ProfileNotifier(),
              lazy: true,
            ),
            ChangeNotifierProxyProvider<LoginNotifier, ChatNotifier>(
              create: (_) => ChatNotifier(),
              update: (_, login, prev) => prev ?? ChatNotifier(),
              lazy: true,
            ),
            ChangeNotifierProxyProvider<LoginNotifier, FilterNotifier>(
              create: (_) => FilterNotifier(),
              update: (_, login, prev) => prev ?? FilterNotifier(),
              lazy: true,
            ),
          ],
          child: MyApp(
            isLoggedIn: data.isLoggedIn,
            onboardingComplete: data.onboardingComplete,
            onboardingPage: data.onboardingPage,
            prefs: data.prefs,
            isPendingVerification: data.isPendingVerification,
            pendingEmail: data.pendingEmail,
            pendingUsername: data.pendingUsername,
          ),
        );
      },
    );
  }

  /// Initialize heavy services in background (doesn't block UI)
  /// This runs AFTER the splash screen is shown
  void _initializeInBackground() {
    // Only initialize once per app lifecycle
    if (_backgroundInitialized) return;
    _backgroundInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Initialize Firebase services
        await FirebaseService.initializeAsync();

        debugPrint('✅ Background initialization complete');
      } catch (e) {
        debugPrint('❌ Background init error: $e');
      }
    });
  }

  static bool _backgroundInitialized = false;
}

/// Data model for initialization state
class _AppInitData {
  final SharedPreferences prefs;
  final bool isLoggedIn;
  final bool onboardingComplete;
  final int onboardingPage;
  final bool isPendingVerification;
  final String pendingEmail;
  final String pendingUsername;

  _AppInitData({
    required this.prefs,
    required this.isLoggedIn,
    required this.onboardingComplete,
    required this.onboardingPage,
    this.isPendingVerification = false,
    this.pendingEmail = '',
    this.pendingUsername = '',
  });
}
