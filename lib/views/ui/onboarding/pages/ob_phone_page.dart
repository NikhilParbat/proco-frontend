import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OnboardingFlowProvider>().phone,
    );
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
      title: "What's your\nphone number?",
      subtitle: "Used to help people connect with you.",
      body: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF1C1C1E), // dropdown background
        ),
        child: IntlPhoneField(
          controller: _controller,
          initialCountryCode: 'IN',
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          dropdownTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          flagsButtonPadding: const EdgeInsets.only(left: 8, right: 4),
          dropdownIcon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white54,
          ),
          cursorColor: kTeal,
          showCountryFlag: true,
          showDropdownIcon: true,

          decoration: const InputDecoration(
            hintText: 'Phone Number',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 22),
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 18),

            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: kTeal, width: 2),
            ),
          ),

          onChanged: (phone) {
            context.read<OnboardingFlowProvider>().phone = phone.completeNumber;
          },
        ),
      ),
      onNext: () {
        final phone = context.read<OnboardingFlowProvider>().phone;

        if (phone == null || phone.isEmpty) {
          Get.snackbar(
            'Phone required',
            'Please enter your phone number to continue.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }

        if (phone.length < 8) {
          Get.snackbar(
            'Invalid phone',
            'Please enter a valid phone number.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }

        provider.nextPage();
      },
    );
  }
}
