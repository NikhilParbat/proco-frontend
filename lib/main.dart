import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:proco/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/my_app.dart'; // Make sure this path is correct

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  // 1. Tell Flutter to wait for initialization
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Load env vars before anything touches Config
    await dotenv.load(fileName: '.env');

    // 3. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Load all your local data BEFORE the app starts
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if user is logged in (Adjust these keys to match your login logic)
    bool isLoggedIn = prefs.getString('token') != null;
    bool onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    int onboardingPage = prefs.getInt('onboardingPage') ?? 0;

    // Check for pending verification (adjust keys if needed)
    bool isPending = prefs.getBool('isPendingVerification') ?? false;
    String pEmail = prefs.getString('pendingEmail') ?? '';
    String pUser = prefs.getString('pendingUsername') ?? '';

    // 4. Start the app with all the data ready
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ZoomNotifier()),
          ChangeNotifierProvider(create: (_) => LoginNotifier()),
          ChangeNotifierProvider(create: (_) => OnBoardNotifier(), lazy: true),
          ChangeNotifierProvider(create: (_) => SignUpNotifier(), lazy: true),
          ChangeNotifierProvider(create: (_) => ImageNotifier(), lazy: true),
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
          prefs: prefs,
          isPendingVerification: isPending,
          pendingEmail: pEmail,
          pendingUsername: pUser,
        ),
      ),
    );
  } catch (e) {
    debugPrint("Fatal Startup Error: $e");
    // Show a simple error screen if everything fails
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Error starting app: $e"))),
      ),
    );
  }
}
