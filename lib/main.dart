import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, FlutterError;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/app_initializer.dart';
import 'package:proco/firebase_options.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Background handler Firebase init failed: $e');
  }
}

Future<void> main() async {
  // Run the whole app inside a guarded zone so that any uncaught async error
  // is logged instead of crashing the process. This is the single most
  // important safety net for production stability.
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // All Google Fonts are bundled as assets (see pubspec). Never fetch them
      // over the network — this eliminates first-frame stalls / font flicker.
      GoogleFonts.config.allowRuntimeFetching = false;

      if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};

      // Never let a widget build error take the whole screen down with a red
      // box in production — show a minimal, branded fallback instead.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        originalOnError?.call(details);
      };
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          color: Color(0xFFF4F6FA),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Something went wrong.\nPlease try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ),
        );
      };

      // Orientation lock (mobile). Non-fatal if it fails.
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } catch (e) {
        debugPrint('Orientation lock failed: $e');
      }

      // .env must never crash startup. If it is missing/corrupt we continue
      // with whatever defaults Config provides.
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('dotenv load failed (continuing with defaults): $e');
      }

      // Firebase init is non-fatal: the app should still open (in a degraded
      // state) even if Firebase is unreachable on a cold start.
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        debugPrint('Firebase init failed: $e');
      }

      runApp(const AppInitializer());
    },
    (error, stack) {
      // Last line of defence for any uncaught async error.
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}
