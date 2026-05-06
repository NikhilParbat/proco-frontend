import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/common/phone_field.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObPhonePage extends StatefulWidget {
  const ObPhonePage({super.key});

  @override
  State<ObPhonePage> createState() => _ObPhonePageState();
}

class _ObPhonePageState extends State<ObPhonePage> {
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _phone = context.read<OnboardingFlowProvider>().phone;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return ObScaffold(
      title: "What's your\nphone number?",
      subtitle: "Used to help people connect with you.",
      body: PhoneInputField(
        darkMode: true,
        initialValue: _phone,
        onChanged: (v) => setState(() => _phone = v),
      ),
      onNext: () {
        final phone = _phone.trim();
        if (phone.isEmpty) {
          Get.snackbar(
            'Phone required',
            'Please enter your phone number to continue.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
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
