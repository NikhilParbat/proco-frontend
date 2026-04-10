import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObDobPage extends StatefulWidget {
  const ObDobPage({super.key});

  @override
  State<ObDobPage> createState() => _ObDobPageState();
}

class _ObDobPageState extends State<ObDobPage> {
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;

  List<String> get _days =>
      List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));

  List<String> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(
      currentYear - 1949 - 13, // oldest = 1950, must be ≥13 years old
      (i) => (currentYear - 13 - i).toString(),
    );
  }

  bool get _isComplete =>
      _selectedDay != null && _selectedMonth != null && _selectedYear != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return ObScaffold(
      title: "When's your\nbirthday?",
      subtitle: "Your date of birth helps us personalise your experience.",
      nextEnabled: _isComplete,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day ──────────────────────────────────────────────────────────
          _DropdownField(
            label: 'Day',
            hint: 'DD',
            value: _selectedDay,
            items: _days,
            onChanged: (v) => setState(() => _selectedDay = v),
          ),
          const SizedBox(height: 16),

          // ── Month ─────────────────────────────────────────────────────────
          _DropdownField(
            label: 'Month',
            hint: 'Month',
            value: _selectedMonth,
            items: _months,
            onChanged: (v) => setState(() => _selectedMonth = v),
          ),
          const SizedBox(height: 16),

          // ── Year ──────────────────────────────────────────────────────────
          _DropdownField(
            label: 'Year',
            hint: 'YYYY',
            value: _selectedYear,
            items: _years,
            onChanged: (v) => setState(() => _selectedYear = v),
          ),

          // ── Preview ───────────────────────────────────────────────────────
          if (_isComplete) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kTeal.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: kTeal, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '$_selectedDay $_selectedMonth $_selectedYear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      onNext: () {
        if (!_isComplete) {
          Get.snackbar(
            'Date of birth required',
            'Please select your full date of birth.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
        // Store as ISO "YYYY-MM-DD" for backend
        final monthIndex = (_months.indexOf(_selectedMonth!) + 1)
            .toString()
            .padLeft(2, '0');
        provider.dob = '$_selectedYear-$monthIndex-$_selectedDay';
        provider.nextPage();
      },
    );
  }
}

// ── Shared dropdown widget ─────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0D2233),
          iconEnabledColor: kTeal,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kTeal, width: 1.5),
            ),
          ),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
