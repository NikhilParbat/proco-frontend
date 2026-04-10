import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:async'; // Required for Timer
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/common/height_spacer.dart';
import 'package:proco/views/ui/auth/login.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  void initState() {
    super.initState();
    // Start the timer when the screen is initialized
    _startDelay();
  }

  void _startDelay() {
    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Use Get.off to remove Onboarding from the navigation stack
        // so the user can't "back" into it.
        Get.off(
          () => const LoginPage(drawer: false),
          transition: Transition.fadeIn, // Smooth transition
          duration: const Duration(milliseconds: 800),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: width,
        height: height,
        color: const Color(0xFF040326),
        child: Column(
          children: [
            const HeightSpacer(size: 205),
            // Your Vector Logo
            Image.asset('assets/images/Vector.png'),

            const HeightSpacer(size: 30),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  'Connecting The Right People\nAt The Right Time',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF08959D),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Optional: A small loading indicator to let users know it's loading
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08959D)),
              ),
            ),

            const HeightSpacer(size: 60),
          ],
        ),
      ),
    );
  }
}
