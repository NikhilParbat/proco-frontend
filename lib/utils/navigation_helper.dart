import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationHelper {
  /// Get MainScreen with prefs loaded
  static Future<Widget> getMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return MainScreen(prefs: prefs);
  }

  /// Navigate to MainScreen using Get
  static Future<void> navigateToMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    Get.offAll(() => MainScreen(prefs: prefs), transition: Transition.fade);
  }
}
