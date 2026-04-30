import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/views/common/drawer/drawer_screen.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/auth/profile_screen.dart';
import 'package:proco/views/ui/bookmarks/bookmarks.dart';
import 'package:proco/views/ui/chat/chat_list.dart';
import 'package:proco/views/ui/homepage.dart';
import 'package:proco/views/ui/jobs/user_job_page.dart';
import 'package:proco/views/ui/settings/settings_page.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final SharedPreferences? prefs; // ✅ Make it optional

  const MainScreen({super.key, this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ZoomDrawerController _drawerController = ZoomDrawerController();

  String _userId = '';
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = widget.prefs ?? await SharedPreferences.getInstance();

    _userId = _prefs?.getString('userId') ?? '';

    if (mounted) {
      setState(() => _isInitialized = true);
    }

    // ✅ ONLY light task
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LoginNotifier>().getPrefs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox();

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
          mainScreen: _buildCurrentScreen(zoomNotifier.currentIndex),
          borderRadius: 30,
          showShadow: true,
          angle: 0,
          slideWidth: 250,
          menuBackgroundColor: kTeal,
        );
      },
    );
  }

  Widget _buildCurrentScreen(int index) {
    final loginNotifier = context.read<LoginNotifier>();

    switch (index) {
      case 0:
        return HomePage(userId: _userId);
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
            ? const SettingsPage()
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
        return HomePage(userId: _userId);
    }
  }
}
