import 'package:flutter/material.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/services/helpers/notification_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/profile/profile_screen.dart';
import 'package:proco/views/ui/bookmarks/bookmarks.dart';
import 'package:proco/views/ui/chat/chat_list.dart';
import 'package:proco/views/ui/homepage.dart';
import 'package:proco/views/ui/jobs/jobs_list.dart';
import 'package:proco/views/ui/settings/settings_page.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final SharedPreferences? prefs;

  const MainScreen({super.key, this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
    final token = _prefs?.getString('token') ?? '';

    // LOAD UI IMMEDIATELY
    if (mounted) {
      setState(() => _isInitialized = true);
    }

    // Run heavy work AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      context.read<LoginNotifier>().getPrefs();

      // Initialize notifications in background
      if (_userId.isNotEmpty && token.isNotEmpty) {
        Future.microtask(() async {
          try {
            await NotificationHelper.initialize(_userId, token);
            debugPrint("✅ NotificationHelper initialized");
          } catch (e) {
            debugPrint("❌ Notification init failed: $e");
          }
        });
      }

      // Register navigator callback
      NotificationHelper.registerTabNavigator((tab) {
        if (mounted) {
          context.read<ZoomNotifier>().currentIndex = tab;
        }
      });

      // Handle pending notification navigation
      final pendingTab = NotificationHelper.pendingTabIndex;

      if (pendingTab != null) {
        NotificationHelper.pendingTabIndex = null;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.read<ZoomNotifier>().currentIndex = pendingTab;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox();

    return Consumer<ZoomNotifier>(
      builder: (context, zoomNotifier, child) {
        return _buildCurrentScreen(zoomNotifier.currentIndex);
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
            ? const JobListPage()
            : const LoginPage(drawer: false);
      case 4:
        return loginNotifier.loggedIn
            ? const ProfilePage()
            : const LoginPage(drawer: false);
      case 5:
        return loginNotifier.loggedIn
            ? const SettingsPage()
            : const LoginPage(drawer: false);
      default:
        return HomePage(userId: _userId);
    }
  }
}
