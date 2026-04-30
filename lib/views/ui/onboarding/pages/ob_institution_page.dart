import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObInstitutionPage extends StatefulWidget {
  const ObInstitutionPage({super.key});

  @override
  State<ObInstitutionPage> createState() => _ObInstitutionPageState();
}

class _ObInstitutionPageState extends State<ObInstitutionPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OnboardingFlowProvider>().institution,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingFlowProvider>();

    // Label adapts to the role chosen earlier.
    final isStudent = provider.role == 'Student';
    final title = isStudent
        ? "Which university\ndo you attend?"
        : "Where do you\nwork?";
    final hint = isStudent ? 'University name' : 'Company / office name';

    return ObScaffold(
      title: title,
      subtitle: isStudent
          ? 'Enter your college or university name.'
          : 'Enter your company or organisation name.',
      nextLabel: 'Finish',
      isLoading: provider.isLoading,
      onSkip: () => provider.submit(),
      body: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 100,
        inputFormatters: [noEmojiFormatter],
        style: const TextStyle(color: Colors.white, fontSize: 20),
        cursorColor: kTeal,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(
            isStudent ? Icons.school_outlined : Icons.business_outlined,
            color: Colors.white38,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: kTeal, width: 2),
          ),
        ),
      ),
      onNext: () {
        final institution = _controller.text.trim();
        if (institution.isEmpty) {
          Get.snackbar(
            isStudent ? 'University required' : 'Workplace required',
            'Please enter this field to continue.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
        provider.institution = institution;
        provider.submit();
      },
    );
  }
}
