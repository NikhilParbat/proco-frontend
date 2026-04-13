import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/signup_provider.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/custom_textfield_input.dart';
import 'package:provider/provider.dart';

/// Sign-up screen: 4 steps — choose method → email → password → verify email.
/// Profile details (name, dob, phone, location, institution) are collected
/// in the post-signup OnboardingFlow.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(0.065.sh),
              child: CustomAppBar(
                text: 'Sign Up',
                child: GestureDetector(
                  onTap: () {
                    if (provider.activeIndex > 0) {
                      provider.changeStep(provider.activeIndex - 1);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: kTeal,
                    size: 20,
                  ),
                ),
              ),
            ),
            body: IndexedStack(
              index: provider.activeIndex,
              children: [
                _choicePage(provider),
                _emailPage(provider),
                _passwordPage(provider),
                _verifyEmailPage(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Step 0: Google or Email ──────────────────────────────────────────────────

  Widget _choicePage(SignUpNotifier provider) {
    return Scaffold(
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("Join ProCo"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.googleSignUp(),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Continue with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider(color: Colors.white30)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text("OR", style: TextStyle(color: Colors.white54)),
                ),
                Expanded(child: Divider(color: Colors.white30)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => provider.changeStep(1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Continue with Email"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Email ────────────────────────────────────────────────────────────

  Widget _emailPage(SignUpNotifier provider) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("What's your email?"),
            const SizedBox(height: 15),
            CustomTextFieldInput(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _nextButton(
              onTap: () {
                final email = _emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  _snack(
                    'Invalid Email',
                    'Please enter a valid email address.',
                  );
                  return;
                }
                provider.signupModel.email = email;
                // Temporary username from email prefix; user sets their real
                // name on the first onboarding page.
                provider.signupModel.username = email.split('@').first;
                provider.changeStep(2);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Password ─────────────────────────────────────────────────────────

  Widget _passwordPage(SignUpNotifier provider) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("Create a\nsecure password"),
            const SizedBox(height: 15),
            CustomTextFieldInput(
              controller: _passwordController,
              hintText: 'Password',
              keyboardType: TextInputType.text,
              obscureText: provider.obscureText,
              suffixIcon: GestureDetector(
                onTap: () => provider.obscureText = !provider.obscureText,
                child: Icon(
                  provider.obscureText
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '8+ chars • uppercase • lowercase • digit • special character',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 20),
            provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: kTeal))
                : _nextButton(
                    onTap: () {
                      if (!provider.passwordValidator(
                        _passwordController.text,
                      )) {
                        _snack(
                          'Weak Password',
                          'Need 8+ chars, uppercase, lowercase, digit & special character.',
                        );
                        return;
                      }
                      provider.signupModel.password = _passwordController.text;
                      provider.submitEmailSignup();
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Email Verification Pending ───────────────────────────────────────

  Widget _verifyEmailPage(SignUpNotifier provider) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF040326),
      body: Center(
        child: _card(
          children: [
            _cardTitle("Check your\ninbox 📬"),
            const SizedBox(height: 12),
            Text(
              'We sent a verification link to:\n${provider.signupModel.email}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click the link in the email, then come back and tap the button below.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 28),
            // Primary action — checked only on tap
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.checkingVerification || provider.isLoading
                    ? null
                    : () => provider.checkVerifiedAndProceed(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  disabledBackgroundColor: kTeal.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.checkingVerification || provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "I've verified my email",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: provider.checkingVerification || provider.isLoading
                    ? null
                    : () => provider.resendVerificationEmail(),
                child: const Text(
                  'Resend email',
                  style: TextStyle(color: kTeal, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08979F), Color(0xFF040326)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _cardTitle(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 26.sp,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );

  Widget _nextButton({required VoidCallback onTap}) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipOval(
            child: Image.asset(
              'assets/images/Sign_in_circle.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: kLightBlue,
      colorText: Colors.white,
    );
  }
}
