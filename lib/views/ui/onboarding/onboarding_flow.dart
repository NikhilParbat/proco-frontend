import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:proco/constants/app_constants.dart';
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

  static const _pages = <Widget>[
    ObChatIntroPage(),
  ];

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
        backgroundColor: const Color(0xFF040326),
        appBar: AppBar(
          backgroundColor: const Color(0xFF040326),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: kTeal, size: 20),
            onPressed: goBack,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: _ProgressBar(
              current: provider.currentPage,
              total: _pages.length,
            ),
          ),
        ),
        body: PageView(
          controller: provider.pageController,
          // Swiping is disabled so only the buttons drive navigation.
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: List.generate(total, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= current ? kTeal : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
