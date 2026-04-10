import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObPhonePage extends StatefulWidget {
  const ObPhonePage({super.key});

  @override
  State<ObPhonePage> createState() => _ObPhonePageState();
}

class _ObPhonePageState extends State<ObPhonePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return ObScaffold(
      title: "What's your\nphone number?",
      subtitle: "Used to help people connect with you.",
      body: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
        maxLength: 15,
        style: const TextStyle(color: Colors.white, fontSize: 22),
        cursorColor: kTeal,
        decoration: const InputDecoration(
          hintText: '+91 00000 00000',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 22),
          counterText: '',
          prefixIcon: Icon(Icons.phone_outlined, color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: kTeal, width: 2),
          ),
        ),
      ),
      onNext: () {
        final phone = _controller.text.trim();
        if (phone.isEmpty) {
          Get.snackbar(
            'Phone required',
            'Please enter your phone number to continue.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
        // Strip non-digits for length check
        final digits = phone.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 7) {
          Get.snackbar(
            'Invalid phone',
            'Please enter a valid phone number.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
        provider.phone = phone;
        provider.nextPage();
      },
    );
  }
}
