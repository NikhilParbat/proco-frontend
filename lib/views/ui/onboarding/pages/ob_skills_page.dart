import 'package:flutter/material.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObSkillsPage extends StatefulWidget {
  const ObSkillsPage({super.key});

  @override
  State<ObSkillsPage> createState() => _ObSkillsPageState();
}

class _ObSkillsPageState extends State<ObSkillsPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _skills = [];

  void _addSkill() {
    final skill = _controller.text.trim();
    if (skill.isEmpty) return;
    if (_skills.contains(skill)) {
      _controller.clear();
      return;
    }
    setState(() {
      _skills.add(skill);
      _controller.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
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
      title: "What are your\nskills?",
      subtitle: "Add skills that describe your expertise.",
      nextLabel: 'Finish',
      onSkip: () {
        provider.skills = [];
        provider.submit();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  cursorColor: kTeal,
                  onSubmitted: (_) => _addSkill(),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Flutter, Python…',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kTeal, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addSkill,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chips
          if (_skills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  backgroundColor: kTeal.withValues(alpha: 0.25),
                  side: BorderSide(color: kTeal.withValues(alpha: 0.6)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                  onDeleted: () => _removeSkill(skill),
                );
              }).toList(),
            )
          else
            const Text(
              'No skills added yet — you can always add them later.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
        ],
      ),
      onNext: () {
        provider.skills = List.from(_skills);
        provider.submit();
      },
    );
  }
}
