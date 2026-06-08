import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:proco/constants/app_colors.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/services/token_store.dart';
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
  // Drives the rippling motion of the wave lines.
  late final AnimationController _waveCtrl;
  // Fades the whole stack in on first frame.
  late final AnimationController _fadeCtrl;

  // Keep the screen visible long enough to read, even if jobs preload instantly.
  static const Duration _minShow = Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
    _waveCtrl.dispose();
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
              SizedBox(
                width: 140.w,
                height: 84.h,
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: _WaveStackPainter(progress: _waveCtrl.value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a stack of horizontal sine-wave lines that ripple sideways — the
/// animated cousin of the drawer's `Icons.waves_rounded` mark.
class _WaveStackPainter extends CustomPainter {
  _WaveStackPainter({required this.progress});

  /// 0..1 looping phase from the controller.
  final double progress;

  static const int _lines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.height / (_lines + 1);
    final amplitude = gap * 0.55;

    for (var i = 0; i < _lines; i++) {
      // Front lines (higher i) are more opaque; the stack recedes upward.
      final opacity = 0.30 + 0.70 * (i / (_lines - 1));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = kSend.withValues(alpha: opacity);

      final baseY = gap * (i + 1);
      // Each line is phase-shifted so the stack ripples rather than moving in
      // lockstep.
      final phase = progress * 2 * math.pi + i * (math.pi / 3);

      final path = Path();
      for (double x = 0; x <= size.width; x += 2) {
        final y =
            baseY +
            amplitude * math.sin((x / size.width) * 2 * math.pi * 1.6 + phase);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveStackPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
