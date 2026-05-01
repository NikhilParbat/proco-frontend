import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:proco/app_initializer.dart';
import 'package:proco/firebase_options.dart';
import 'package:proco/services/notification_background.dart';

const _channelId = 'proco_alerts';
const _channelName = 'ProCo Alerts';

Future<void> _createAndroidNotificationChannel() async {
  if (!Platform.isAndroid) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must be registered before runApp() — handles background/terminated state
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Create high-importance channel so FCM notifications show as heads-up
  await _createAndroidNotificationChannel();

  runApp(const AppInitializer());
}
