import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/onboarding/pages/ob_chat_intro_page.dart';

class OnboardingFlow extends StatelessWidget {
  final String initialName;
  final int initialPage;

  const OnboardingFlow({
    super.key,
    this.initialName = '',
    this.initialPage = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingFlowProvider(
        initialName: initialName,
        initialPage: initialPage,
      ),
      child: const _OnboardingFlowBody(),
    );
  }
}

class _OnboardingFlowBody extends StatelessWidget {
  const _OnboardingFlowBody();

  static const _pages = <Widget>[ObChatIntroPage()];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingFlowProvider>();

    void goBack() {
      if (provider.currentPage > 0) {
        provider.prevPage();
      } else {
        Get.offAll(
          () => const LoginPage(drawer: false),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 400),
        );
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: PageView(
            controller: provider.pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
        ),
      ),
    );
  }
}
