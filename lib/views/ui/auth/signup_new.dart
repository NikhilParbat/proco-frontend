import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/constants/app_text_styles.dart';
import 'package:proco/controllers/signup_provider.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/custom_textfield_input.dart';
import 'package:provider/provider.dart';

/// Sign-up screen: 4 steps — choose method → email → password → verify email.
/// Profile details (name, dob, phone, location, institution) are collected
/// in the post-signup OnboardingFlow.
class SignUpScreen extends StatefulWidget {
  final int initialStep;
  final String initialEmail;
  final String initialUsername;

  const SignUpScreen({
    super.key,
    this.initialStep = 0,
    this.initialEmail = '',
    this.initialUsername = '',
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final SignUpNotifier _provider;

  @override
  void initState() {
    super.initState();
    _provider = SignUpNotifier();
    if (widget.initialEmail.isNotEmpty) {
      _emailController.text = widget.initialEmail;
      _provider.signupModel.email = widget.initialEmail;
      _provider.signupModel.username = widget.initialUsername;
      _provider.activeIndex = widget.initialStep;
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<SignUpNotifier>(
        builder: (context, provider, _) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: kBackgroundColor,
            appBar: const LagoonAppBar(),
            body: provider.activeIndex == 3
                ? _verifyEmailPage(provider)
                : _signupPage(provider),
          );
        },
      ),
    );
  }

  // ── Signup page: email + password + Sign Up + Google ─────────────────────────

  Widget _signupPage(SignUpNotifier provider) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0.04.sh),

              Text(
                'Sign Up',
                style: kHeadingStyle.copyWith(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 0.05.sh),

              CustomTextFieldInput(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                hintStyle: kSubTextStyle.copyWith(
                  color: const Color.fromARGB(255, 20, 20, 20),
                  fontWeight: FontWeight.w400,
                ),
                textStyle: kSubTextStyle.copyWith(
                  color: const Color.fromARGB(255, 20, 20, 20),
                ),
              ),

              SizedBox(height: 16.h),

              CustomTextFieldInput(
                controller: _passwordController,
                hintText: 'Password',
                keyboardType: TextInputType.text,
                obscureText: provider.obscureText,
                maxLength: 20,
                inputFormatters: [noEmojiFormatter],
                hintStyle: kSubTextStyle.copyWith(
                  color: const Color.fromARGB(255, 20, 20, 20),
                  fontWeight: FontWeight.w400,
                ),
                textStyle: kSubTextStyle.copyWith(
                  color: const Color.fromARGB(255, 20, 20, 20),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => provider.obscureText = !provider.obscureText,
                  child: Icon(
                    provider.obscureText
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black54,
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                '8+ chars • uppercase • lowercase • digit • special character',
                style: kSmallTextStyle.copyWith(fontSize: 11.sp),
              ),

              SizedBox(height: 0.04.sh),

              // Sign Up button
              provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kThemeColor),
                    )
                  : GestureDetector(
                      onTap: () {
                        final email = _emailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          _snack(
                            'Invalid Email',
                            'Please enter a valid email address.',
                          );
                          return;
                        }
                        if (!provider.passwordValidator(
                          _passwordController.text,
                        )) {
                          _snack(
                            'Weak Password',
                            'Need 8+ chars, uppercase, lowercase, digit & special character.',
                          );
                          return;
                        }
                        provider.signupModel.email = email;
                        provider.signupModel.username = email.split('@').first;
                        provider.signupModel.password =
                            _passwordController.text;
                        provider.submitEmailSignup();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 55.h,
                        decoration: BoxDecoration(
                          color: kThemeColor,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Sign Up',
                          style: kSubTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

              SizedBox(height: 20.h),

              // OR divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: kDarkGrey.withValues(alpha: 0.4)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text('OR', style: kSmallTextStyle),
                  ),
                  Expanded(
                    child: Divider(color: kDarkGrey.withValues(alpha: 0.4)),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Sign up with Google
              GestureDetector(
                onTap: provider.isLoading
                    ? null
                    : () => provider.googleSignUp(),
                child: Container(
                  width: double.infinity,
                  height: 55.h,
                  decoration: BoxDecoration(
                    color: kThemeColor,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  alignment: Alignment.center,
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/google_icon.png',
                              height: 24.h,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.g_mobiledata,
                                size: 28.h,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Sign up with Google',
                              style: kSubTextStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 25.h),

              // Already have an account
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: kSubTextStyle),
                      Text(
                        'Login',
                        style: kSubTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 0.04.sh),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 3: Email Verification Pending ───────────────────────────────────────

  Widget _verifyEmailPage(SignUpNotifier provider) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0.04.sh),

              Text(
                'Check your\ninbox 📬',
                style: kHeadingStyle.copyWith(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                'We sent a verification link to:\n${provider.signupModel.email}',
                style: kSubTextStyle,
              ),

              SizedBox(height: 12.h),

              Text(
                'Click the link in the email, then come back and tap the button below.',
                style: kSmallTextStyle,
              ),

              SizedBox(height: 0.05.sh),

              // Primary action — checked only on tap
              GestureDetector(
                onTap: provider.checkingVerification || provider.isLoading
                    ? null
                    : () => provider.checkVerifiedAndProceed(),
                child: Container(
                  width: double.infinity,
                  height: 55.h,
                  decoration: BoxDecoration(
                    color: provider.checkingVerification || provider.isLoading
                        ? kThemeColor.withValues(alpha: 0.4)
                        : kThemeColor,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  alignment: Alignment.center,
                  child: provider.checkingVerification || provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "I've verified my email",
                          style: kSubTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 12.h),

              Center(
                child: TextButton(
                  onPressed: provider.checkingVerification || provider.isLoading
                      ? null
                      : () => provider.resendVerificationEmail(),
                  child: Text(
                    'Resend email',
                    style: kSubTextStyle.copyWith(
                      color: kThemeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: kLightBlue,
      colorText: Colors.white,
    );
  }
}
