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

  // ✅ Cache user data
  String _userId = '';
  String _token = '';
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  // ✅ Load prefs if not provided
  Future<void> _initializePrefs() async {
    if (widget.prefs != null) {
      _prefs = widget.prefs;
      _extractUserData();
    } else {
      _prefs = await SharedPreferences.getInstance();
      _extractUserData();
    }

    // ✅ Schedule background tasks AFTER build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initBackgroundTasks();
      }
    });
  }

  void _extractUserData() {
    if (_prefs != null) {
      _userId = _prefs!.getString('userId') ?? '';
      _token = _prefs!.getString('token') ?? '';
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  // ✅ All heavy operations run asynchronously, non-blocking
  Future<void> _initBackgroundTasks() async {
    // Run in parallel
    await Future.wait([
      _loadLoginPrefs(),
      _preloadJobsIfNeeded(),
      _setupNotificationsIfNeeded(),
    ]);
  }

  Future<void> _loadLoginPrefs() async {
    if (mounted) {
      context.read<LoginNotifier>().getPrefs();
    }
  }

  Future<void> _preloadJobsIfNeeded() async {
    // ✅ Only preload if on HomePage (index 0)
    final zoomNotifier = context.read<ZoomNotifier>();
    if (zoomNotifier.currentIndex == 0 && _userId.isNotEmpty) {
      if (mounted) {
        context.read<JobsNotifier>().preloadJobs(_userId);
      }
    }
  }

  Future<void> _setupNotificationsIfNeeded() async {
    if (_userId.isNotEmpty && _token.isNotEmpty) {
      await NotificationHelper.initialize(_userId, _token);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show loading while initializing prefs
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<ZoomNotifier>(
      builder: (context, zoomNotifier, child) {
        return ZoomDrawer(
          controller: _drawerController,
          menuScreen: DrawerScreen(
            controller: _drawerController,
            indexSetter: (index) {
              zoomNotifier.currentIndex = index;
              // ✅ Preload jobs when navigating to HomePage
              if (index == 0 && _userId.isNotEmpty) {
                Future.microtask(() {
                  if (mounted) {
                    context.read<JobsNotifier>().preloadJobs(_userId);
                  }
                });
              }
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

  // ✅ Memoized screen builder
  Widget _buildCurrentScreen(int index) {
    final loginNotifier = context.read<LoginNotifier>();

    switch (index) {
      case 0:
        return HomePage(userId: _userId); // ✅ Pass userId
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
