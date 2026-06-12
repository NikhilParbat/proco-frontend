import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/constants/app_text_styles.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:proco/views/ui/profile/profile_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Springy elastic bounce for the central celebration asset
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    // Smooth fade-in sequence for text fields and buttons
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    // Run the celebration pop instantly on screen entry
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              
              // Brand Anchor Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lagoon.',
                  style: kSectionTitleStyle.copyWith(
                    fontSize: 20.sp,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(),

              // Celebratory Core: Animated Canvas + Badge Pop
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Radial Soft Glow Burst
                      Container(
                        width: 260.w,
                        height: 260.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              kReceive.withOpacity(0.35 * _controller.value),
                              kSend.withOpacity(0.2 * _controller.value),
                              kLight.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      
                      // Custom Confetti/Geometric Burst Ring
                      CustomPaint(
                        size: Size(280.w, 280.w),
                        painter: CelebrationParticlePainter(
                          progress: _controller.value,
                        ),
                      ),
                      
                      // Core Elastic Identity Badge
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: const BoxDecoration(
                            color: kDark,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: kReceive,
                            size: 46.w,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),

              // Sequenced Fade-In Text Block (Generalized Copy)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      "You're all set!",
                      style: kHeadingStyle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        "We've queued up potential opportunities matching your background. Your next collaborator is just a swipe away.",
                        style: kBodyStyle.copyWith(
                          color: const Color(0xFF4A4A4A),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),

              // Action Matrix Stack
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Primary Solid Interactive Core
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle navigational transition to main layout/swipe card stack
                          Get.offAll(() => const MainScreen(), transition: Transition.fade);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'Explore Opportunities',
                          style: kButtonTextStyle.copyWith(letterSpacing: 1),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    // Secondary Fine-grain Check Core
                    GestureDetector(
                      onTap: () {
                        // View profile configuration drawer/screen
                        Get.offAll(const ProfilePage(), transition: Transition.fade);
                      },
                      child: Text(
                        'View Profile',
                        style: kSmallTextStyle.copyWith(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                          color: kDark.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Computes custom geometric velocity trajectories mapping exact colors 
/// from user chat configurations for clean, vector-based execution loops.
class CelebrationParticlePainter extends CustomPainter {
  final double progress;
  CelebrationParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Random random = Random(42); // Seed guarantees static distribution generation

    // Structural metrics for particle design pools using your imported global colors
    final List<Color> colors = [kSend, kReceive, kDark];
    const int totalParticles = 24;

    for (int i = 0; i < totalParticles; i++) {
      final double angle = (i * (2 * pi / totalParticles)) + random.nextDouble() * 0.4;
      
      // Exploding acceleration curve layout metrics
      final double currentProgress = Curves.easeOutCubic.transform(progress);
      final double startRadius = 55.w;
      final double maxExtension = 70.w + random.nextDouble() * 50.w;
      final double currentRadius = startRadius + (maxExtension * currentProgress);

      final double x = center.dx + cos(angle) * currentRadius;
      final double y = center.dy + sin(angle) * currentRadius;

      final Paint paint = Paint()
        ..color = colors[random.nextInt(colors.length)].withOpacity(1.0 - currentProgress)
        ..style = PaintingStyle.fill;

      // Swap between drawing clean circular bubbles or crisp diamonds dynamically
      if (i % 2 == 0) {
        final double radius = (4.w + random.nextDouble() * 4.w) * (1.0 - (currentProgress * 0.5));
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else {
        final double side = (6.w + random.nextDouble() * 6.w) * (1.0 - (currentProgress * 0.5));
        final Path diamondPath = Path()
          ..moveTo(x, y - side)
          ..lineTo(x + side, y)
          ..lineTo(x, y + side)
          ..lineTo(x - side, y)
          ..close();
        canvas.drawPath(diamondPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CelebrationParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}