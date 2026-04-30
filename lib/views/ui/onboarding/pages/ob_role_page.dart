import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

/// NOTE: The 'role' field (Student / Young Professional) has no matching
/// field in the backend user schema yet. The selection is stored in the
/// provider but is NOT sent to the backend. Add a `userType` (or equivalent)
/// field to the backend and wire it up in ProfileUpdateReq / UserHelper.
class ObRolePage extends StatefulWidget {
  const ObRolePage({super.key});

  @override
  State<ObRolePage> createState() => _ObRolePageState();
}

class _ObRolePageState extends State<ObRolePage> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    final saved = context.read<OnboardingFlowProvider>().role;
    if (saved.isNotEmpty) _selected = saved;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return ObScaffold(
      title: "What best describes\nyou?",
      subtitle: "Help us personalise your experience.",
      nextEnabled: _selected != null,
      body: Column(
        children: [
          _RoleCard(
            label: 'Student',
            icon: Icons.school_outlined,
            description: 'Currently pursuing a degree or course.',
            selected: _selected == 'Student',
            onTap: () => setState(() => _selected = 'Student'),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            label: 'Young Professional',
            icon: Icons.work_outline,
            description: 'Working in the industry.',
            selected: _selected == 'Young Professional',
            onTap: () => setState(() => _selected = 'Young Professional'),
          ),
        ],
      ),
      onNext: () {
        if (_selected == null) {
          Get.snackbar(
            'Selection required',
            'Please choose one to continue.',
            backgroundColor: kOrange,
            colorText: kLight,
          );
          return;
        }
        provider.role = _selected!;
        provider.nextPage();
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? kTeal.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kTeal : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? kTeal : Colors.white54, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? kTeal : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: kTeal, size: 22),
          ],
        ),
      ),
    );
  }
}
