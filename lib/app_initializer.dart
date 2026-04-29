import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:proco/main.dart';
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

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await dotenv.load(fileName: ".env");

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    isLoggedIn = token != null && token.isNotEmpty;
    onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    onboardingPage = prefs.getInt('onboardingPage') ?? 0;

    await ScreenUtil.ensureScreenSize();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnBoardNotifier()),
        ChangeNotifierProvider(create: (_) => LoginNotifier()),
        ChangeNotifierProvider(create: (_) => ZoomNotifier()),
        ChangeNotifierProvider(create: (_) => SignUpNotifier()),
        ChangeNotifierProvider(create: (_) => JobsNotifier()),
        ChangeNotifierProvider(create: (_) => BookMarkNotifier()),
        ChangeNotifierProvider(create: (_) => ImageNotifier()),
        ChangeNotifierProvider(create: (_) => ProfileNotifier()),
        ChangeNotifierProvider(create: (_) => ChatNotifier()),
        ChangeNotifierProvider(create: (_) => FilterNotifier()),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
        onboardingComplete: onboardingComplete,
        onboardingPage: onboardingPage,
      ),
    );
  }
}
