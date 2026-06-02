import 'package:flutter/material.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/services/helpers/notification_helper.dart';
import 'package:proco/services/token_store.dart';
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

  // Tabs that have been opened at least once. Only these are built inside the
  // IndexedStack; the rest stay as lightweight placeholders until first visited
  // (lazy-load), and once built they are kept alive so switching tabs never
  // re-runs initState or re-fetches data.
  final Set<int> _activatedTabs = {0};

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    // Credentials via TokenStore (in-memory on web, prefs on mobile).
    _userId = await TokenStore.getUserId() ?? '';
    final token = await TokenStore.getToken() ?? '';

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

    // Only rebuild when the selected tab actually changes (Selector instead of
    // Consumer avoids rebuilding the whole stack on unrelated notifications).
    return Selector<ZoomNotifier, int>(
      selector: (_, z) => z.currentIndex,
      builder: (context, index, child) {
        _activatedTabs.add(index);

        return IndexedStack(
          index: index,
          children: List.generate(6, (i) {
            // Lazy: build a tab only after it has been visited at least once.
            if (!_activatedTabs.contains(i)) {
              return const SizedBox.shrink();
            }
            return _buildScreen(i);
          }),
        );
      },
    );
  }

  Widget _buildScreen(int index) {
    final loggedIn = context.read<LoginNotifier>().loggedIn;

    switch (index) {
      case 0:
        return HomePage(userId: _userId);
      case 1:
        return loggedIn ? const ChatsList() : const LoginPage(drawer: false);
      case 2:
        return loggedIn ? const BookMarkPage() : const LoginPage(drawer: false);
      case 3:
        return loggedIn ? const JobListPage() : const LoginPage(drawer: false);
      case 4:
        return loggedIn ? const ProfilePage() : const LoginPage(drawer: false);
      case 5:
        return loggedIn ? const SettingsPage() : const LoginPage(drawer: false);
      default:
        return HomePage(userId: _userId);
    }
  }
}
