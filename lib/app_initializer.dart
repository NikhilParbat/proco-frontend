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

  // ✅ Cache SharedPreferences instance
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Get SharedPreferences once and cache it
    _prefs = await SharedPreferences.getInstance();

    final token = _prefs.getString('token');
    isLoggedIn = token != null && token.isNotEmpty;
    onboardingComplete = _prefs.getBool('onboardingComplete') ?? false;
    onboardingPage = _prefs.getInt('onboardingPage') ?? 0;

    // Render UI ASAP
    if (mounted) {
      setState(() => isLoading = false);
    }

    // ✅ Load everything else in background
    Future.wait([
      dotenv.load(fileName: ".env").catchError((e) {
        debugPrint('Failed to load .env: $e');
      }),
      FirebaseService.initializeAsync(), // ✅ Non-blocking Firebase
    ]);
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
      ),
    );
  }
}
