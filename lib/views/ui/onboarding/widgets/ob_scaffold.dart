import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';

/// Shared scaffold used by every onboarding step page.
class ObScaffold extends StatelessWidget {
  const ObScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.onNext,
    this.isLoading = false,
    this.nextLabel = 'Continue',
    this.nextEnabled = true,
    this.onSkip,
  });

  final String title;
  final String? subtitle;

  /// The main content area (text field, chips, etc.)
  final Widget body;

  final VoidCallback onNext;
  final bool isLoading;
  final String nextLabel;
  final bool nextEnabled;

  /// When provided, a "Skip" button appears in the top-right corner.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip button row — only rendered when onSkip is provided
              if (onSkip != null)
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: isLoading ? null : onSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 0),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
              const SizedBox(height: 36),
              body,
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (isLoading || !nextEnabled) ? null : onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal,
                    disabledBackgroundColor: kTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          nextLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
