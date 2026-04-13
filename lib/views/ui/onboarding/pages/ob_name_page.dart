import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObNamePage extends StatefulWidget {
  const ObNamePage({super.key});

  @override
  State<ObNamePage> createState() => _ObNamePageState();
}

class _ObNamePageState extends State<ObNamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OnboardingFlowProvider>();
    _controller = TextEditingController(text: provider.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return ObScaffold(
      title: "What should we\ncall you?",
      subtitle: "This is how you'll appear to other professionals.",
      body: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 50,
        inputFormatters: [noEmojiFormatter],
        style: const TextStyle(color: Colors.white, fontSize: 20),
        cursorColor: kTeal,
        decoration: const InputDecoration(
          hintText: 'Full name',
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: kTeal, width: 2),
          ),
        ),
      ),
      onNext: () {
        final name = _controller.text.trim();
        if (name.isEmpty) {
          Get.snackbar(
            'Name required',
            'Please enter your name to continue.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
        provider.name = name;
        provider.nextPage();
      },
    );
  }
}
