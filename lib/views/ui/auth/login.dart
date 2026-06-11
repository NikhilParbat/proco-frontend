import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/constants/app_text_styles.dart';
import 'package:proco/controllers/login_provider.dart';
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/custom_textfield_input.dart';
import 'package:proco/views/common/wave_loader.dart';
import 'package:proco/views/ui/auth/signup_new.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.drawer, super.key});
  final bool drawer;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginNotifier loginNotifier) async {
    if (loginNotifier.validateAndSave()) {
      final model = LoginRequestModel(
        email: email.text,
        password: password.text,
      );
      setState(() => _isLoginLoading = true);

      await loginNotifier.userLogin(model);

      if (mounted) {
        setState(() => _isLoginLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginNotifier>().getPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginNotifier>(
      builder: (context, loginNotifier, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          // Page background set to kbackgroundColor
          backgroundColor: kBackgroundColor,
          appBar: const LagoonAppBar(showDrawer: false),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: Form(
                  key: loginNotifier.loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 0.04.sh),

                      Text('Login', style: kHeadingStyle),

                      SizedBox(height: 0.05.sh),

                      CustomTextFieldInput(
                        key: const Key('email_field'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Username',
                        hintStyle: kSubTextStyle.copyWith(
                          color: const Color.fromARGB(255, 20, 20, 20),
                          fontWeight: FontWeight.w400,
                        ),
                        textStyle: kSubTextStyle.copyWith(
                          color: const Color.fromARGB(255, 20, 20, 20),
                        ),
                        validator: (val) {
                          if (val!.isEmpty || !val.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20.h),

                      // Password Field[cite: 1]
                      Selector<LoginNotifier, bool>(
                        selector: (context, notifier) => notifier.obscureText,
                        builder: (context, isObscured, child) {
                          return CustomTextFieldInput(
                            key: const ValueKey('pass_field'),
                            controller: password,
                            keyboardType: TextInputType.text,
                            hintText: 'Password',
                            hintStyle: kSubTextStyle.copyWith(
                              color: const Color.fromARGB(255, 20, 20, 20),
                              fontWeight: FontWeight.w400,
                            ),
                            textStyle: kSubTextStyle.copyWith(
                              color: const Color.fromARGB(255, 20, 20, 20),
                            ),
                            obscureText: isObscured,
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  context.read<LoginNotifier>().obscureText =
                                      !isObscured,
                              child: Icon(
                                isObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black54,
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Invalid password' : null,
                          );
                        },
                      ),

                      SizedBox(height: 15.h),

                      // Forgot Password - Right aligned, Using kSubTextStyle[cite: 1]
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // Logic preserved[cite: 1]
                          },
                          child: Text('Forgot Password?', style: kSubTextStyle),
                        ),
                      ),

                      SizedBox(height: 0.04.sh),

                      // Login Button - kThemeColor, Pill Shape[cite: 1]
                      GestureDetector(
                        onTap: _isLoginLoading
                            ? null
                            : () => _handleLogin(loginNotifier),
                        child: Container(
                          width: double.infinity,
                          height: 55.h,
                          decoration: BoxDecoration(
                            color: kThemeColor,
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          alignment: Alignment.center,
                          child: _isLoginLoading
                              ? const WaveLoader.small()
                              : Text(
                                  'Login',
                                  style: kSubTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 25.h),

                      // Signup Link - Centered, Using kSubTextStyle[cite: 1]

                      // Google Sign-In Button - Pill Shape, Using kSubTextStyle[cite: 1]
                      GestureDetector(
                        onTap: _isGoogleLoading
                            ? null
                            : () async {
                                setState(() => _isGoogleLoading = true);

                                await loginNotifier.googleSignIn();

                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          height: 55.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4C4C4),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: _isGoogleLoading
                              ? const Center(child: WaveLoader.small())
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/google_icon.png',
                                      height: 24.h,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.login,
                                              size: 24.h,
                                              color: Colors.black,
                                            );
                                          },
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Login using Google',
                                      style: kSubTextStyle.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 0.02.sh),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => const SignUpScreen());
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: kSubTextStyle,
                              ),
                              Text(
                                "Signup",
                                style: kSubTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kThemeColor,
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
            ),
          ),
        );
      },
    );
  }
}
