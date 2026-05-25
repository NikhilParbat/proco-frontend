import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/constants/skills_constants.dart';

/// Text field that shows live autocomplete suggestions from [kAllSkills].
/// The user can only add a skill by tapping a suggestion or submitting an
/// exact match — free-form text is not accepted.
class SkillSearchField extends StatefulWidget {
  const SkillSearchField({
    super.key,
    required this.onSelected,
    this.alreadySelected = const [],
    this.hint = 'Search and add a skill...',
    this.enabled = true,
    this.fillColor = Colors.white,
  });

  final ValueChanged<String> onSelected;
  final List<String> alreadySelected;
  final String hint;
  final bool enabled;
  final Color fillColor;

  @override
  State<SkillSearchField> createState() => _SkillSearchFieldState();
}

class _SkillSearchFieldState extends State<SkillSearchField> {
  final _ctrl = TextEditingController();
  List<String> _suggestions = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() {
      _suggestions = suggestSkills(query, limit: 8)
          .where((s) => !widget.alreadySelected.contains(s))
          .toList();
    });
  }

  void _select(String skill) {
    widget.onSelected(skill);
    _ctrl.clear();
    setState(() => _suggestions = []);
  }

  // Allow pressing Enter if the typed text is an exact skill name.
  void _onSubmitted(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    final match = kAllSkills.firstWhere(
      (s) => s.toLowerCase() == q,
      orElse: () => '',
    );
    if (match.isNotEmpty && !widget.alreadySelected.contains(match)) {
      _select(match);
    } else {
      // Shake / clear so the user knows the entry was rejected.
      _ctrl.clear();
      setState(() => _suggestions = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          enabled: widget.enabled,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 14.sp,
            color: kDark,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 13.sp,
              color: const Color(0xFF9EA4B0),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18.sp,
              color: const Color(0xFF9EA4B0),
            ),
            filled: true,
            fillColor: widget.fillColor,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: kLightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: kLightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: kThemeColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: kLightGrey),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Container(
            constraints: BoxConstraints(maxHeight: 180.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFD2D6DE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, i) {
                final skill = _suggestions[i];
                return InkWell(
                  onTap: () => _select(skill),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 13.sp,
                        color: kDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
