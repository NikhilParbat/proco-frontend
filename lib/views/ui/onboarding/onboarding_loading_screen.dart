import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/services/token_store.dart';
import 'package:proco/views/common/wave_loader.dart';
import 'package:proco/views/ui/mainscreen.dart';

/// Shown once, right after the conversational onboarding finishes, to bridge
/// the gap before the home page appears (previously the home screen popped up
/// abruptly). White canvas, black Montserrat caption, and an animated stack of
/// wave lines drawn in the same blue used in the onboarding chat — mirroring
/// the `waves` mark from the drawer header.
class OnboardingLoadingScreen extends StatefulWidget {
  const OnboardingLoadingScreen({super.key});

  @override
  State<OnboardingLoadingScreen> createState() =>
      _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends State<OnboardingLoadingScreen>
    with TickerProviderStateMixin {
  // Fades the whole stack in on first frame.
  late final AnimationController _fadeCtrl;

  // Keep the screen visible long enough to read, even if jobs preload instantly.
  static const Duration _minShow = Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _bootstrap();
  }

  /// Warm up the home feed during the wait so the swiper is ready on arrival,
  /// then move on once the minimum display time has elapsed.
  Future<void> _bootstrap() async {
    final started = DateTime.now();

    try {
      final userId = await TokenStore.getUserId() ?? '';
      if (mounted && userId.isNotEmpty) {
        final bookmarkedIds = context.read<BookMarkNotifier>().jobs;
        // Fire-and-forget: home page also preloads, and this is cache-first.
        context.read<JobsNotifier>().preloadJobs(
          userId,
          bookmarkedIds: bookmarkedIds,
        );
      }
    } catch (_) {
      // Non-fatal — the home page preloads its own data regardless.
    }

    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minShow) {
      await Future.delayed(_minShow - elapsed);
    }
    if (!mounted) return;
    Get.offAll(() => const MainScreen(), transition: Transition.fade);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Let's take you on\nthe shore",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 28.h),
              const WaveLoader(width: 140, height: 84),
            ],
          ),
        ),
      ),
    );
  }
}
