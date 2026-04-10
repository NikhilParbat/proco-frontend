import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/login_provider.dart';
import 'package:proco/models/request/auth/login_model.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/custom_textfield_input.dart';
import 'package:proco/views/common/drawer/drawer_widget.dart';
import 'package:proco/views/common/exports.dart';
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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginNotifier loginNotifier) async {
    if (loginNotifier.validateAndSave()) {
      final model = LoginModel(email: email.text, password: password.text);
      await loginNotifier.userLogin(model);
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
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(0.065.sh),
            child: CustomAppBar(
              text: 'Log In',
              child: widget.drawer
                  ? Padding(
                      padding: EdgeInsets.all(8.0.h),
                      child: const DrawerWidget(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          backgroundColor: const Color(0xFF040326),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Form(
                  key: loginNotifier.loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 0.02.sh),

                      // Title
                      Text(
                        'Login to Your Account',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 0.04.sh),

                      // Email Field
                      CustomTextFieldInput(
                        key: const Key('email_field'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Email',
                        validator: (email) {
                          if (email!.isEmpty || !email.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20.h),

                      // Password Field
                      Selector<LoginNotifier, bool>(
                        selector: (context, notifier) => notifier.obscureText,
                        builder: (context, isObscured, child) {
                          return CustomTextFieldInput(
                            key: const ValueKey('pass_field'),
                            controller: password,
                            keyboardType: TextInputType.text,
                            hintText: 'Password',
                            obscureText: isObscured,
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  context.read<LoginNotifier>().obscureText =
                                      !isObscured,
                              child: Icon(
                                isObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Invalid password' : null,
                          );
                        },
                      ),

                      SizedBox(height: 15.h),

                      // Forgot Password & Create Account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Implement forgot password functionality
                            },
                            child: ReusableText(
                              text: 'Forgot Password?',
                              style: appstyle(
                                12,
                                Colors.white70,
                                FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const SignUpScreen());
                            },
                            child: ReusableText(
                              text: "Create Account",
                              style: appstyle(
                                14,
                                Color(0xFF08979F),
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 0.04.sh),

                      // Login Button
                      GestureDetector(
                        onTap: loginNotifier.isLoading
                            ? null
                            : () => _handleLogin(loginNotifier),
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF08979F), Color(0xFF06656A)],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF08979F).withValues(alpha:0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: loginNotifier.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Divider with "OR"
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.white30, thickness: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.white30, thickness: 1),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Google Sign-In Button
                      GestureDetector(
                        onTap: () async {
                          await loginNotifier.googleSignIn();
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google_icon.png',
                                height: 24.h,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.login,
                                    size: 24.h,
                                    color: const Color(0xFF040326),
                                  );
                                },
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF040326),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 0.02.sh),
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
