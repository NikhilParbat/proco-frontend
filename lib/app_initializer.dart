import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  bool isLoading = true;
  bool isLoggedIn = false;
  bool onboardingComplete = false;
  int onboardingPage = 0;
  bool isPendingVerification = false;
  String pendingEmail = '';
  String pendingUsername = '';

  // ✅ Cache SharedPreferences instance
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Let Flutter render first frame first
    await Future.delayed(const Duration(milliseconds: 50));

    // Get SharedPreferences once and cache it
    _prefs = await SharedPreferences.getInstance();

    final token = _prefs.getString('token');

    isLoggedIn = token != null && token.isNotEmpty;

    onboardingComplete = _prefs.getBool('onboardingComplete') ?? false;

    onboardingPage = _prefs.getInt('onboardingPage') ?? 0;

    // ✅ Render UI immediately
    if (mounted) {
      setState(() => isLoading = false);
    }

    // Run heavy initialization AFTER first render
    Future.microtask(() async {
      bool firebaseLoaded = false;

      // If not logged in, check pending verification
      if (!isLoggedIn) {
        final savedEmail = _prefs.getString('pendingVerificationEmail') ?? '';

        if (savedEmail.isNotEmpty) {
          try {
            await Future.wait([
              if (!kIsWeb) dotenv.load(fileName: ".env").catchError((e) {
                debugPrint('Failed to load .env: $e');
              }) else Future.value(),

              FirebaseService.initializeAsync(),
            ]);

            firebaseLoaded = true;

            final fbUser = FirebaseAuth.instance.currentUser;

            if (fbUser != null &&
                fbUser.email == savedEmail &&
                !fbUser.emailVerified) {
              if (!mounted) return;

              setState(() {
                isPendingVerification = true;
                pendingEmail = savedEmail;
                pendingUsername =
                    _prefs.getString('pendingVerificationUsername') ?? '';
              });
            } else {
              await _prefs.remove('pendingVerificationEmail');

              await _prefs.remove('pendingVerificationUsername');
            }
          } catch (e) {
            debugPrint('AppInitializer: error checking Firebase user: $e');
          }
        }
      }

      // Background initialization if not already loaded
      if (!firebaseLoaded) {
        Future.wait([
          if (!kIsWeb) dotenv.load(fileName: ".env").catchError((e) {
            debugPrint('Failed to load .env: $e');
          }) else Future.value(),

          FirebaseService.initializeAsync(),
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        // ✅ Core providers (always needed)
        ChangeNotifierProvider(create: (_) => ZoomNotifier()),
        ChangeNotifierProvider(create: (_) => LoginNotifier()),

        // ✅ Lazy providers (only created when accessed)
        ChangeNotifierProvider(create: (_) => OnBoardNotifier(), lazy: true),
        ChangeNotifierProvider(create: (_) => SignUpNotifier(), lazy: true),
        ChangeNotifierProvider(create: (_) => ImageNotifier(), lazy: true),

        // ✅ Super lazy providers (depend on login state)
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
        isLoggedIn: isLoggedIn,
        onboardingComplete: onboardingComplete,
        onboardingPage: onboardingPage,
        prefs: _prefs,
        isPendingVerification: isPendingVerification,
        pendingEmail: pendingEmail,
        pendingUsername: pendingUsername,
      ),
    );
  }
}
