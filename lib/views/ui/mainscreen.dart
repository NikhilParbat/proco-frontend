import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/services/helpers/notification_helper.dart';
import 'package:proco/views/common/drawer/drawer_screen.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/auth/profile_screen.dart';
import 'package:proco/views/ui/bookmarks/bookmarks.dart';
import 'package:proco/views/ui/chat/chat_list.dart';
import 'package:proco/views/ui/device_mgt/devices_info.dart';
import 'package:proco/views/ui/homepage.dart';
import 'package:proco/views/ui/jobs/user_job_page.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ZoomDrawerController _drawerController = ZoomDrawerController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ZoomNotifier>(
      builder: (context, zoomNotifier, child) {
        return ZoomDrawer(
          controller: _drawerController,
          menuScreen: DrawerScreen(
            controller: _drawerController,
            indexSetter: (index) {
              zoomNotifier.currentIndex = index;
            },
          ),
          mainScreen: Builder(
            builder: (context) {
              return currentScreen();
            },
          ),
          borderRadius: 30,
          showShadow: true,
          angle: 0,
          slideWidth: 250,
          menuBackgroundColor: kTeal,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        context.read<LoginNotifier>().getPrefs();
        _preloadJobs();
        _setupNotifications();
      }
    });
  }

  Future<void> _preloadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (mounted) {
      context.read<JobsNotifier>().preloadJobs(userId);
    }
  }

  Future<void> _setupNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';
    if (userId.isNotEmpty && token.isNotEmpty) {
      await NotificationHelper.initialize(userId, token);
    }
  }

  Widget currentScreen() {
    final zoomNotifier = Provider.of<ZoomNotifier>(context, listen: false);
    final loginNotifier = Provider.of<LoginNotifier>(context, listen: false);
    switch (zoomNotifier.currentIndex) {
      case 0:
        return const HomePage();
      case 1:
        return loginNotifier.loggedIn
            ? const ChatsList()
            : const LoginPage(drawer: false);
      case 2:
        return loginNotifier.loggedIn
            ? const BookMarkPage()
            : const LoginPage(drawer: false);
      case 3:
        return loginNotifier.loggedIn
            ? const DeviceManagement()
            : const LoginPage(drawer: false);
      case 4:
        return loginNotifier.loggedIn
            ? const JobListingPage()
            : const LoginPage(drawer: false);
      case 5:
        return loginNotifier.loggedIn
            ? const ProfilePage()
            : const LoginPage(drawer: false);
      default:
        return const HomePage();
    }
  }
}
