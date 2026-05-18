import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:proco/constants/app_constants.dart';
import 'package:proco/services/location_service.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/phone_field.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:provider/provider.dart';
import 'profile_state.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const int _kMaxLinks = 6;
const int _kMaxChips = 12;

// ── Validation helpers ────────────────────────────────────────────────────────
final _gibberishRegExp = RegExp(r'''^[a-zA-Z0-9 .,\-\'\"@#&()/:\\+!?%\n\r]+$''');

bool _isValidText(String text) {
  if (text.trim().isEmpty) return true;
  return _gibberishRegExp.hasMatch(text.trim());
}

// ── Page ──────────────────────────────────────────────────────────────────────
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditState(),
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        drawer: const LagoonDrawer(),
        appBar: AppBar(
          backgroundColor: kThemeColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kLight, size: 18),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: kLight,
            ),
          ),
        ),
        body: Consumer<ProfileEditState>(
          builder: (context, state, _) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: kThemeColor),
              );
            }
            return _EditForm(state: state);
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Consumer<ProfileEditState>(
          builder: (context, state, _) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FloatingActionButton.extended(
                heroTag: 'saveBtn',
                onPressed: state.isSaving
                    ? null
                    : () async {
                        final ok = await state.saveProfile(null);
                        if (ok && context.mounted) {
                          Get.snackbar(
                            'Profile Saved',
                            'Your profile has been updated.',
                            backgroundColor: kTeal,
                            colorText: kLight,
                            duration: const Duration(seconds: 3),
                          );
                        }
                      },
                backgroundColor: state.isSaving
                    ? kThemeColor.withValues(alpha: 0.5)
                    : kThemeColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                label: state.isSaving
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: kLight,
                        ),
                      )
                    : Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: kLight,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── EditForm with continuous single scroll layout ──────────────────────────────
class _EditForm extends StatefulWidget {
  const _EditForm({required this.state});
  final ProfileEditState state;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
            children: [
              // ── 1. About ─────────────────────────────────────────────────
              _IdentitySection(state: widget.state),
              SizedBox(height: 20.h),

              // ── 2. Personal ──────────────────────────────────────────────
              PhoneInputField(
                initialValue: widget.state.phone,
                onChanged: (v) => widget.state.phone = v,
              ),
              SizedBox(height: 14.h),
              _GenderSelector(
                value: widget.state.gender,
                onChanged: (v) => widget.state.gender = v,
              ),
              SizedBox(height: 14.h),
              _DOBPicker(
                value: widget.state.dob,
                onChanged: (v) => widget.state.dob = v,
              ),
              SizedBox(height: 20.h),
              // Education sub-section
              _SubSectionTitle(title: 'Education'),
              ...widget.state.education.asMap().entries.map((entry) {
                final index = entry.key;
                final edu = entry.value;
                return _ExpandableCard(
                  label: edu.college.isEmpty ? 'Institution ${index + 1}' : edu.college,
                  icon: Icons.school_outlined,
                  onEdit: () => _showEducationDialog(
                    context,
                    widget.state,
                    index: index,
                    existing: edu,
                  ),
                  onDelete: () => widget.state.removeEducation(index),
                  subtitle: '${edu.degree}${edu.branch.isNotEmpty ? " • ${edu.branch}" : ""}',
                );
              }),
              _AddButton(
                label: 'ADD EDUCATION',
                onPressed: () => _showEducationDialog(context, widget.state),
              ),
              SizedBox(height: 20.h),
              // Achievements sub-section
              _SubSectionTitle(title: 'Achievements'),
              ...widget.state.achievements.asMap().entries.map((entry) {
                final index = entry.key;
                final ach = entry.value;
                return _ExpandableCard(
                  label: ach.title.isEmpty ? 'Achievement ${index + 1}' : ach.title,
                  icon: Icons.emoji_events_outlined,
                  onEdit: () => _showAchievementDialog(
                    context,
                    widget.state,
                    index: index,
                    existing: ach,
                  ),
                  onDelete: () => widget.state.removeAchievement(index),
                  subtitle: ach.subtitle,
                );
              }),
              _AddButton(
                label: 'ADD ACHIEVEMENT',
                onPressed: () => _showAchievementDialog(
                  context,
                  widget.state,
                ),
              ),
              SizedBox(height: 20.h),

              // ── 3. Professional ──────────────────────────────────────────
              _SubSectionTitle(title: 'Work Style'),
              _OptionSelector(
                label: 'Work Style',
                value: widget.state.workStyle,
                options: const ['Remote-first', 'Hybrid', 'In-office', 'Flexible'],
                onChanged: (v) => widget.state.workStyle = v,
              ),
              SizedBox(height: 14.h),
              _OptionSelector(
                label: 'Communication Style',
                value: widget.state.communicationStyle,
                options: const ['Asynchronous', 'Synchronous', 'Mixed'],
                onChanged: (v) => widget.state.communicationStyle = v,
              ),
              SizedBox(height: 20.h),
              _SubSectionTitle(title: 'Experience'),
              ...widget.state.experiences.asMap().entries.map((entry) {
                final index = entry.key;
                final exp = entry.value;
                return _ExpandableCard(
                  label: exp.company.isEmpty ? 'Experience ${index + 1}' : exp.company,
                  icon: Icons.work_outline,
                  subtitle: exp.position,
                  onEdit: () => _showExperienceDialog(
                    context,
                    widget.state,
                    index: index,
                    existing: exp,
                  ),
                  onDelete: () => widget.state.removeExperience(index),
                );
              }),
              _AddButton(
                label: 'ADD EXPERIENCE',
                onPressed: () => _showExperienceDialog(context, widget.state),
              ),
              SizedBox(height: 20.h),
              _SubSectionTitle(title: 'Projects'),
              ...widget.state.projects.asMap().entries.map((entry) {
                final index = entry.key;
                final proj = entry.value;
                return _ExpandableCard(
                  label: proj.name.isEmpty ? 'Project ${index + 1}' : proj.name,
                  icon: Icons.code_outlined,
                  subtitle: proj.technologies.isNotEmpty
                      ? proj.technologies.join(', ')
                      : '',
                  onEdit: () => _showProjectDialog(
                    context,
                    widget.state,
                    index: index,
                    existing: proj,
                  ),
                  onDelete: () => widget.state.removeProject(index),
                );
              }),
              _AddButton(
                label: 'ADD PROJECT',
                onPressed: () => _showProjectDialog(context, widget.state),
              ),
              SizedBox(height: 20.h),
              _SubSectionTitle(title: 'Links'),
              _ValidatedField(
                label: 'LinkedIn URL',
                init: widget.state.linkedInUrl,
                onChanged: (v) => widget.state.linkedInUrl = v,
                keyboard: TextInputType.url,
                hint: 'https://linkedin.com/in/…',
                maxLength: 200,
                allowSpecialChars: true,
              ),
              _ValidatedField(
                label: 'GitHub URL',
                init: widget.state.gitHubUrl,
                onChanged: (v) => widget.state.gitHubUrl = v,
                keyboard: TextInputType.url,
                hint: 'https://github.com/…',
                maxLength: 200,
                allowSpecialChars: true,
              ),
              _ValidatedField(
                label: 'Twitter / X URL',
                init: widget.state.twitterUrl,
                onChanged: (v) => widget.state.twitterUrl = v,
                keyboard: TextInputType.url,
                hint: 'https://twitter.com/…',
                maxLength: 200,
                allowSpecialChars: true,
              ),
              _ValidatedField(
                label: 'Portfolio / Behance URL',
                init: widget.state.portfolioUrl,
                onChanged: (v) => widget.state.portfolioUrl = v,
                keyboard: TextInputType.url,
                hint: 'https://…',
                maxLength: 200,
                allowSpecialChars: true,
              ),
              SizedBox(height: 10.h),
              _LinksEditor(state: widget.state),
              SizedBox(height: 20.h),

              // ── 4. Skills ────────────────────────────────────────────────
              _ChipInputSection(
                label: 'Skills',
                values: widget.state.skills,
                onAdded: (v) => widget.state.addSkill(v),
                onRemoved: (v) => widget.state.removeSkill(v),
              ),
              SizedBox(height: 20.h),
              _ChipInputSection(
                label: 'Interests',
                values: widget.state.interests,
                onAdded: (v) => widget.state.addInterest(v),
                onRemoved: (v) => widget.state.removeInterest(v),
              ),
              SizedBox(height: 14.h),
              _ChipInputSection(
                label: 'Hobbies',
                values: widget.state.hobbies,
                onAdded: (v) => widget.state.addHobbies(v),
                onRemoved: (v) => widget.state.removeHobby(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dialog launchers ──────────────────────────────────────────────────────────
void _showExperienceDialog(
  BuildContext context,
  ProfileEditState state, {
  int? index,
  ExperienceItem? existing,
}) {
  showDialog(
    context: context,
    builder: (_) => _ExperienceDialog(
      state: state,
      index: index,
      existing: existing,
    ),
  );
}

void _showProjectDialog(
  BuildContext context,
  ProfileEditState state, {
  int? index,
  ProjectItem? existing,
}) {
  showDialog(
    context: context,
    builder: (_) => _ProjectDialog(
      state: state,
      index: index,
      existing: existing,
    ),
  );
}

void _showAchievementDialog(
  BuildContext context,
  ProfileEditState state, {
  int? index,
  AchievementItem? existing,
}) {
  showDialog(
    context: context,
    builder: (_) => _AchievementDialog(
      state: state,
      index: index,
      existing: existing,
    ),
  );
}

void _showEducationDialog(
  BuildContext context,
  ProfileEditState state, {
  int? index,
  EducationItem? existing,
}) {
  showDialog(
    context: context,
    builder: (_) => _EducationDialog(
      state: state,
      index: index,
      existing: existing,
    ),
  );
}
// ── Experience Dialog ─────────────────────────────────────────────────────────
class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({required this.state, this.index, this.existing});
  final ProfileEditState state;
  final int? index;
  final ExperienceItem? existing;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  late String _company;
  late String _position;
  late String _description;
  late String _dateRange;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _company = widget.existing?.company ?? '';
    _position = widget.existing?.position ?? '';
    _description = widget.existing?.description ?? '';
    _dateRange = widget.existing?.dateRange ?? '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = ExperienceItem(
      company: _company.trim(),
      position: _position.trim(),
      description: _description.trim(),
      dateRange: _dateRange,
    );
    if (widget.index != null) {
      widget.state.updateExperience(widget.index!, item);
    } else {
      widget.state.addExperience(item);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseDialog(
      title: widget.index != null ? 'Edit Experience' : 'Add Experience',
      icon: Icons.work_outline,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _DialogField(
              label: 'Company Name *',
              init: _company,
              onChanged: (v) => _company = v,
              hint: 'e.g. Google',
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!_isValidText(v)) return 'Invalid characters';
                return null;
              },
            ),
            _DropdownDialogField(
              label: 'Employment Type',
              value: _position.isEmpty ? null : _position,
              items: const [
                'Full-time',
                'Part-time',
                'Internship',
                'Freelance',
                'Contract',
                'Other',
              ],
              hint: 'Select type',
              onChanged: (v) => setState(() => _position = v ?? ''),
              fallbackField: _DialogField(
                label: 'Role / Job Title *',
                init: _position,
                onChanged: (v) => _position = v,
                hint: 'e.g. Software Engineer',
                maxLength: 80,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!_isValidText(v)) return 'Invalid characters';
                  return null;
                },
              ),
            ),
            _DialogField(
              label: 'About the Role',
              init: _description,
              onChanged: (v) => _description = v,
              maxLines: 3,
              hint: 'Describe your responsibilities…',
              maxLength: 500,
              validator: (v) {
                if (v != null && v.isNotEmpty && !_isValidText(v)) {
                  return 'Invalid characters';
                }
                return null;
              },
            ),
            _DateRangePicker(
              value: _dateRange,
              onChanged: (v) => setState(() => _dateRange = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project Dialog ─────────────────────────────────────────────────────────────
class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({required this.state, this.index, this.existing});
  final ProfileEditState state;
  final int? index;
  final ProjectItem? existing;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late String _name;
  late String _domain;
  late String _description;
  late String _techRaw;
  late String _sourceUrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = widget.existing?.name ?? '';
    _domain = widget.existing?.domain ?? '';
    _description = widget.existing?.description ?? '';
    _techRaw = widget.existing?.technologies.join(', ') ?? '';
    _sourceUrl = widget.existing?.sourceUrl ?? '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final techs = _techRaw
        .split(',')
        .map((t) => t.trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toList();
    final item = ProjectItem(
      name: _name.trim(),
      domain: _domain.trim(),
      description: _description.trim(),
      technologies: techs,
      sourceUrl: _sourceUrl.trim(),
    );
    if (widget.index != null) {
      widget.state.updateProject(widget.index!, item);
    } else {
      widget.state.addProject(item);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseDialog(
      title: widget.index != null ? 'Edit Project' : 'Add Project',
      icon: Icons.code_outlined,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _DialogField(
              label: 'Project Name *',
              init: _name,
              onChanged: (v) => _name = v,
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!_isValidText(v)) return 'Invalid characters';
                return null;
              },
            ),
            _DropdownDialogField(
              label: 'Domain',
              value: _domain.isEmpty ? null : _domain,
              items: const [
                'Web Development',
                'Mobile App',
                'Machine Learning / AI',
                'Data Science',
                'Backend / API',
                'DevOps / Cloud',
                'Design / UI',
                'Open Source',
                'Other',
              ],
              hint: 'Select domain',
              onChanged: (v) => setState(() => _domain = v ?? ''),
            ),
            _DialogField(
              label: 'Technologies Used',
              init: _techRaw,
              onChanged: (v) => _techRaw = v,
              hint: 'Flutter, Firebase, Node.js (comma-separated)',
              maxLength: 200,
              validator: (v) {
                if (v != null && v.isNotEmpty && !_isValidText(v)) {
                  return 'Invalid characters';
                }
                return null;
              },
            ),
            _DialogField(
              label: 'Project Description',
              init: _description,
              onChanged: (v) => _description = v,
              maxLines: 3,
              hint: 'What does this project do?',
              maxLength: 500,
              validator: (v) {
                if (v != null && v.isNotEmpty && !_isValidText(v)) {
                  return 'Invalid characters';
                }
                return null;
              },
            ),
            _DialogField(
              label: 'Project URL / Source Code',
              init: _sourceUrl,
              onChanged: (v) => _sourceUrl = v,
              hint: 'https://github.com/…',
              keyboard: TextInputType.url,
              maxLength: 200,
              allowSpecialChars: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievement Dialog ────────────────────────────────────────────────────────
class _AchievementDialog extends StatefulWidget {
  const _AchievementDialog({required this.state, this.index, this.existing});
  final ProfileEditState state;
  final int? index;
  final AchievementItem? existing;

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog> {
  late String _title;
  late String _subtitle;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _title = widget.existing?.title ?? '';
    _subtitle = widget.existing?.subtitle ?? '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = AchievementItem(
      title: _title.trim(),
      subtitle: _subtitle.trim(),
      icon: widget.existing?.icon ?? 'star',
    );
    if (widget.index != null) {
      widget.state.updateAchievement(widget.index!, item);
    } else {
      widget.state.addAchievement(item);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseDialog(
      title: widget.index != null ? 'Edit Achievement' : 'Add Achievement',
      icon: Icons.emoji_events_outlined,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _DialogField(
              label: 'Title *',
              init: _title,
              onChanged: (v) => _title = v,
              hint: 'e.g. Hackathon Winner',
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!_isValidText(v)) return 'Invalid characters';
                return null;
              },
            ),
            _DialogField(
              label: 'Description',
              init: _subtitle,
              onChanged: (v) => _subtitle = v,
              hint: 'e.g. Secured 1st rank among 50 teams',
              maxLength: 300,
              validator: (v) {
                if (v != null && v.isNotEmpty && !_isValidText(v)) {
                  return 'Invalid characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Education Dialog ─────────────────────────────────────────────────────────
class _EducationDialog extends StatefulWidget {
  const _EducationDialog({required this.state, this.index, this.existing});
  final ProfileEditState state;
  final int? index;
  final EducationItem? existing;

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  late String _college;
  late String _degree;
  late String _branch;
  late String _classOf;
  late String _cgpa;
  final _formKey = GlobalKey<FormState>();

  // Predefined lists for academic drop-downs
  static const List<String> _degreeOptions = [
    'BTech / BE',
    'MTech / ME',
    'BSc',
    'MSc',
    'BCA',
    'MCA',
    'BBA',
    'MBA',
    'PhD',
    'BDesign',
    'MDesign',
    'BArch',
    'MArch',
    'BCom',
    'MCom',
    'Other',
  ];

  static const List<String> _branchOptions = [
    'Computer Science & Engineering',
    'Data Science & Artificial Intelligence',
    'Information Technology',
    'Electronics & Communication Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Aerospace Engineering',
    'Biotechnology',
    'Design (UI/UX, Product, Fashion, etc.)',
    'Architecture',
    'Business / Commerce',
    'Other / General',
  ];

  @override
  void initState() {
    super.initState();
    _college = widget.existing?.college ?? '';
    _degree = widget.existing?.degree ?? '';
    _branch = widget.existing?.branch ?? '';
    _classOf = widget.existing?.classOf ?? '';
    _cgpa = widget.existing?.cgpa ?? '';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = EducationItem(
      college: _college.trim(),
      degree: _degree.trim(),
      branch: _branch.trim(),
      classOf: _classOf,
      cgpa: _cgpa.trim(),
    );
    if (widget.index != null) {
      widget.state.updateEducation(widget.index!, item);
    } else {
      widget.state.addEducation(item);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseDialog(
      title: widget.index != null ? 'Edit Education' : 'Add Education',
      icon: Icons.school_outlined,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _DialogField(
              label: 'Institution / College Name *',
              init: _college,
              onChanged: (v) => _college = v,
              hint: 'e.g. IIT Bombay',
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!_isValidText(v)) return 'Invalid characters';
                if (v.trim().length < 2) return 'Name too short';
                return null;
              },
            ),
            _DropdownDialogField(
              label: 'Degree *',
              value: _degreeOptions.contains(_degree) ? _degree : null,
              items: _degreeOptions,
              hint: 'Select Degree Type',
              onChanged: (v) => setState(() => _degree = v ?? ''),
            ),
            _DropdownDialogField(
              label: 'Field of Study / Branch',
              value: _branchOptions.contains(_branch) ? _branch : null,
              items: _branchOptions,
              hint: 'Select Specialization',
              onChanged: (v) => setState(() => _branch = v ?? ''),
            ),
            _DropdownDialogField(
              label: 'Graduation Year',
              value: _classOf.isEmpty ? null : _classOf,
              items: List.generate(
                DateTime.now().year - 1990 + 7,
                (i) => (DateTime.now().year + 6 - i).toString(),
              ),
              hint: 'Select Year',
              onChanged: (v) => setState(() => _classOf = v ?? ''),
            ),
            _DialogField(
              label: 'Academic Score (CGPA)',
              init: _cgpa,
              onChanged: (v) => _cgpa = v,
              hint: 'e.g. 8.5',
              maxLength: 10,
              validator: (v) {
                if (v != null && v.isNotEmpty && !_isValidText(v)) {
                  return 'Invalid characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Base Dialog ───────────────────────────────────────────────────────────────
class _BaseDialog extends StatelessWidget {
  const _BaseDialog({
    required this.title,
    required this.icon,
    required this.onSave,
    required this.child,
  });

  final String title;
  final IconData icon;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          color: kLight,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: kThemeColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: kLight, size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: kLight,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: kLight, size: 20),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: child,
              ),
            ),
            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kThemeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: kLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog Field ──────────────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.init,
    required this.onChanged,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength = 200,
    this.validator,
    this.allowSpecialChars = false,
  });

  final String label;
  final String init;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final int maxLength;
  final FormFieldValidator<String>? validator;
  final bool allowSpecialChars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        initialValue: init,
        keyboardType: keyboard,
        onChanged: onChanged,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        style: kSubTextStyle.copyWith(color: kDark, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          labelStyle: kSmallTextStyle.copyWith(color: kDarkGrey, fontSize: 13.sp),
          hintStyle: kSmallTextStyle.copyWith(
            color: const Color(0xFFBBBBBB),
            fontSize: 13.sp,
          ),
          filled: true,
          fillColor: kBackgroundColor,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown Dialog Field ─────────────────────────────────────────────────────
class _DropdownDialogField extends StatelessWidget {
  const _DropdownDialogField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.fallbackField,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final Widget? fallbackField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        hint: Text(
          hint ?? 'Select…',
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 13.sp,
            color: const Color(0xFFBBBBBB),
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: kSmallTextStyle.copyWith(color: kDarkGrey, fontSize: 13.sp),
          filled: true,
          fillColor: kBackgroundColor,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 13.sp,
                      color: kDark,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: kDarkGrey, size: 20.sp),
        dropdownColor: kLight,
        isExpanded: true,
        style: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 13.sp,
          color: kDark,
        ),
      ),
    );
  }
}

// ── Identity Section ──────────────────────────────────────────────────────────
class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.state});
  final ProfileEditState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48.r,
                backgroundColor: kLightGrey,
                backgroundImage: state.profileImageUrl.isNotEmpty
                    ? NetworkImage(state.profileImageUrl)
                    : null,
                child: state.profileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 40.r, color: kDarkGrey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: kThemeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kLight, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, size: 14.r, color: kLight),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _ValidatedField(
          label: 'Full Name',
          init: state.username,
          onChanged: (v) => state.username = v,
          maxLength: 60,
        ),
        _BioField(init: state.bio, onChanged: (v) => state.bio = v),
        _LocationPickerRow(state: state),
      ],
    );
  }
}

// ── Validated Field (with gibberish guard + char limit) ───────────────────────
class _ValidatedField extends StatefulWidget {
  const _ValidatedField({
    required this.label,
    required this.init,
    required this.onChanged,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
    this.maxLength = 200,
    this.allowSpecialChars = false,
  });

  final String label;
  final String init;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final int maxLength;
  final bool allowSpecialChars;

  @override
  State<_ValidatedField> createState() => _ValidatedFieldState();
}

class _ValidatedFieldState extends State<_ValidatedField> {
  String? _error;

  void _validate(String value) {
    if (widget.allowSpecialChars) {
      setState(() => _error = null);
      widget.onChanged(value);
      return;
    }
    if (value.isNotEmpty && !_isValidText(value)) {
      setState(() => _error = 'Invalid characters entered');
    } else {
      setState(() => _error = null);
      widget.onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        initialValue: widget.init,
        keyboardType: widget.keyboard,
        onChanged: _validate,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: kSubTextStyle.copyWith(color: kDark, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: _error,
          counterStyle: TextStyle(fontSize: 10.sp, color: kDarkGrey),
          labelStyle:
              kSmallTextStyle.copyWith(color: kDarkGrey, fontSize: 13.sp),
          hintStyle: kSmallTextStyle.copyWith(
            color: const Color(0xFFBBBBBB),
            fontSize: 13.sp,
          ),
          filled: true,
          fillColor: kLight,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown Field ────────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        hint: Text(
          hint ?? 'Select…',
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 13.sp,
            color: const Color(0xFFBBBBBB),
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              kSmallTextStyle.copyWith(color: kDarkGrey, fontSize: 13.sp),
          filled: true,
          fillColor: kLight,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 13.sp,
                      color: kDark,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: kDarkGrey, size: 20.sp),
        dropdownColor: kLight,
        isExpanded: true,
        style: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 13.sp,
          color: kDark,
        ),
      ),
    );
  }
}

// ── Expandable Card ───────────────────────────────────────────────────────────
class _ExpandableCard extends StatelessWidget {
  const _ExpandableCard({
    required this.label,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: kLightGrey),
      ),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        leading: Icon(icon, size: 20.r, color: kThemeColor),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: kDark,
          ),
        ),
        subtitle: subtitle != null && subtitle!.isNotEmpty
            ? Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 12.sp,
                  color: kDarkGrey,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18.r, color: kThemeColor),
              onPressed: onEdit,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18.r, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location Picker Row ───────────────────────────────────────────────────────
class _LocationPickerRow extends StatefulWidget {
  const _LocationPickerRow({required this.state});
  final ProfileEditState state;

  @override
  State<_LocationPickerRow> createState() => _LocationPickerRowState();
}

class _LocationPickerRowState extends State<_LocationPickerRow> {
  final _locationSearchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _locationResults = [];
  bool _isSearchingLocation = false;
  bool _isFetchingCurrentLocation = false;
  String? _selectedLocationLabel;
  bool _preferTypingLocation = false;

  @override
  void initState() {
    super.initState();
    final parts = [
      widget.state.city,
      widget.state.state,
      widget.state.country,
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) _selectedLocationLabel = parts.join(', ');
  }

  @override
  void dispose() {
    _locationSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLocationSearchChanged(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _locationResults.clear();
        _isSearchingLocation = false;
      });
      return;
    }
    setState(() => _isSearchingLocation = true);
    try {
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'proco_app'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _locationResults
            ..clear()
            ..addAll(data.map((item) {
              final addr = item['address'] as Map<String, dynamic>? ?? {};
              return {
                'display_name': item['display_name'],
                'lat': double.parse(item['lat']),
                'lon': double.parse(item['lon']),
                'city': addr['city'] ??
                    addr['town'] ??
                    addr['village'] ??
                    addr['county'] ??
                    '',
                'state': addr['state'] ?? '',
                'country': addr['country'] ?? '',
              };
            }));
        });
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    } finally {
      if (mounted) setState(() => _isSearchingLocation = false);
    }
  }

  void _selectLocationResult(Map<String, dynamic> item) {
    final lat = item['lat'] as double;
    final lon = item['lon'] as double;
    final display = (item['display_name'] as String?) ?? '';
    widget.state.setLocation(
      city: (item['city'] as String?) ?? '',
      state: (item['state'] as String?) ?? '',
      country: (item['country'] as String?) ?? '',
      latitude: lat,
      longitude: lon,
    );
    setState(() {
      _selectedLocationLabel = display;
      _locationSearchCtrl.text = display;
      _locationResults.clear();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingCurrentLocation = true);
    try {
      final result = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromLatLng(
        result.latitude,
        result.longitude,
      );
      if (!mounted) return;
      final display = result.displayAddress?.isNotEmpty == true
          ? result.displayAddress!
          : '${address.city}, ${address.state}';
      widget.state.setLocation(
        city: address.city,
        state: address.state,
        country: address.country,
        latitude: result.latitude,
        longitude: result.longitude,
      );
      setState(() => _selectedLocationLabel = display);
    } catch (e) {
      Get.snackbar('Location Error', e.toString(),
          backgroundColor: kOrange, colorText: kLight);
    } finally {
      if (mounted) setState(() => _isFetchingCurrentLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _locationChip(
                label: 'Use current location',
                icon: Icons.my_location_rounded,
                selected: !_preferTypingLocation,
                onTap: () => setState(() => _preferTypingLocation = false),
              ),
              _locationChip(
                label: 'Search location',
                icon: Icons.search,
                selected: _preferTypingLocation,
                onTap: () => setState(() => _preferTypingLocation = true),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (!_preferTypingLocation)
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed:
                    _isFetchingCurrentLocation ? null : _useCurrentLocation,
                icon: _isFetchingCurrentLocation
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: kLight),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _isFetchingCurrentLocation
                      ? 'Fetching...'
                      : 'Fetch Current Location',
                  style: TextStyle(
                    color: kLight,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kThemeColor,
                  foregroundColor: kLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kLight,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          size: 18.sp, color: Colors.grey.shade400),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: _locationSearchCtrl,
                          onChanged: _onLocationSearchChanged,
                          style: TextStyle(
                              fontSize: 14.sp, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search city / area',
                            hintStyle: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade400),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSearchingLocation) ...[
                  SizedBox(height: 4.h),
                  const LinearProgressIndicator(
                      minHeight: 2, color: kThemeColor),
                ],
                if (_locationResults.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxHeight: 170.h),
                    decoration: BoxDecoration(
                      color: kLight,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _locationResults.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final item = _locationResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on_outlined,
                              color: Colors.grey.shade600, size: 18.sp),
                          title: Text(
                            item['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.sp, color: Colors.black87),
                          ),
                          onTap: () => _selectLocationResult(item),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          if (_selectedLocationLabel?.isNotEmpty ?? false) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: kThemeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: kThemeColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: kThemeColor, size: 16),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _selectedLocationLabel!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? kThemeColor : kLight,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? kThemeColor : const Color(0xFFDDDDDD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14.sp, color: selected ? kLight : Colors.black54),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: selected ? kLight : Colors.black87,
                fontSize: 13.sp,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip Input Section (max 12) ───────────────────────────────────────────────
class _ChipInputSection extends StatefulWidget {
  const _ChipInputSection({
    required this.label,
    required this.values,
    required this.onAdded,
    required this.onRemoved,
  });

  final String label;
  final List<String> values;
  final ValueChanged<String> onAdded;
  final ValueChanged<String> onRemoved;

  @override
  State<_ChipInputSection> createState() => _ChipInputSectionState();
}

class _ChipInputSectionState extends State<_ChipInputSection> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final val = _controller.text.trim();
    if (val.isEmpty) return;
    if (widget.values.length >= _kMaxChips) {
      setState(() => _error = 'Maximum $_kMaxChips ${widget.label.toLowerCase()} reached');
      return;
    }
    if (!_isValidText(val)) {
      setState(() => _error = 'Invalid characters');
      return;
    }
    if (val.length > 40) {
      setState(() => _error = 'Max 40 characters');
      return;
    }
    setState(() => _error = null);
    widget.onAdded(val);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final atMax = widget.values.length >= _kMaxChips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: kDarkGrey,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '(${widget.values.length}/$_kMaxChips)',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                color: atMax ? Colors.redAccent : kDarkGrey,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: widget.values.map((v) {
              return Chip(
                label: Text(
                  v,
                  style: TextStyle(
                      fontFamily: kFontDMSans, fontSize: 12.sp, color: kDark),
                ),
                backgroundColor: kLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: const BorderSide(color: kLightGrey),
                ),
                deleteIcon:
                    Icon(Icons.close, size: 14.r, color: kDarkGrey),
                onDeleted: () => widget.onRemoved(v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              );
            }).toList(),
          ),
        SizedBox(height: 8.h),
        if (!atMax) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  maxLength: 40,
                  style: TextStyle(
                      fontFamily: kFontDMSans, fontSize: 13.sp, color: kDark),
                  decoration: InputDecoration(
                    hintText: 'Add ${widget.label.toLowerCase()}…',
                    counterText: '',
                    hintStyle: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 13.sp,
                      color: const Color(0xFFBBBBBB),
                    ),
                    filled: true,
                    fillColor: kLight,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.r),
                        bottomLeft: Radius.circular(10.r),
                      ),
                      borderSide: const BorderSide(color: kLightGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.r),
                        bottomLeft: Radius.circular(10.r),
                      ),
                      borderSide: const BorderSide(color: kLightGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.r),
                        bottomLeft: Radius.circular(10.r),
                      ),
                      borderSide: const BorderSide(
                          color: kThemeColor, width: 1.5),
                    ),
                  ),
                  onFieldSubmitted: (_) => _add(),
                ),
              ),
              InkWell(
                onTap: _add,
                child: Container(
                  height: 46.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: kDark,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10.r),
                      bottomRight: Radius.circular(10.r),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: kLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            SizedBox(height: 4.h),
            Text(
              _error!,
              style: TextStyle(
                  fontSize: 11.sp, color: Colors.redAccent,
                  fontFamily: kFontDMSans),
            ),
          ],
        ] else
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
            child: Text(
              'Maximum $_kMaxChips ${widget.label.toLowerCase()} reached.',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                color: kDarkGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Sub-section title ─────────────────────────────────────────────────────────
class _SubSectionTitle extends StatelessWidget {
  const _SubSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 2.h),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: kThemeColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: kDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bio field with 250-word limit ─────────────────────────────────────────────
class _BioField extends StatefulWidget {
  const _BioField({required this.init, required this.onChanged});
  final String init;
  final ValueChanged<String> onChanged;

  @override
  State<_BioField> createState() => _BioFieldState();
}

class _BioFieldState extends State<_BioField> {
  late final TextEditingController _ctrl;
  int _wordCount = 0;
  static const int _maxWords = 250;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.init);
    _wordCount = _countWords(widget.init);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  void _onChanged(String value) {
    if (!_isValidText(value) && value.isNotEmpty) return;
    final count = _countWords(value);
    if (count > _maxWords) {
      final words = value.trim().split(RegExp(r'\s+'));
      final trimmed = words.take(_maxWords).join(' ');
      _ctrl.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      setState(() => _wordCount = _maxWords);
      widget.onChanged(trimmed);
      return;
    }
    setState(() => _wordCount = count);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = _wordCount >= _maxWords;
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _ctrl,
            onChanged: _onChanged,
            maxLines: 5,
            style: kSubTextStyle.copyWith(color: kDark, fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell the world about yourself…',
              labelStyle:
                  kSmallTextStyle.copyWith(color: kDarkGrey, fontSize: 13.sp),
              hintStyle: kSmallTextStyle.copyWith(
                color: const Color(0xFFBBBBBB),
                fontSize: 13.sp,
              ),
              filled: true,
              fillColor: kLight,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
            ),
          ),
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_wordCount / $_maxWords words',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                color: atLimit ? Colors.redAccent : kDarkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Links Editor (single LinkItem list) ───────────────────────────────────────
class _LinksEditor extends StatefulWidget {
  const _LinksEditor({required this.state});
  final ProfileEditState state;

  @override
  State<_LinksEditor> createState() => _LinksEditorState();
}

class _LinksEditorState extends State<_LinksEditor> {
  final _labelCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _labelError;
  String? _urlError;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final label = _labelCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    bool valid = true;
    if (label.isEmpty) {
      setState(() => _labelError = 'Label is required');
      valid = false;
    } else if (!_isValidText(label)) {
      setState(() => _labelError = 'Invalid characters');
      valid = false;
    } else {
      setState(() => _labelError = null);
    }
    if (url.isEmpty) {
      setState(() => _urlError = 'URL is required');
      valid = false;
    } else {
      setState(() => _urlError = null);
    }
    if (!valid) return;
    if (widget.state.links.length >= _kMaxLinks) return;
    setState(() {
      widget.state.links = [
        ...widget.state.links,
        LinkItem(label: label, url: url),
      ];
    });
    _labelCtrl.clear();
    _urlCtrl.clear();
  }

  void _remove(int index) {
    setState(() {
      widget.state.links = List.from(widget.state.links)..removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.state.links;
    final atMax = links.length >= _kMaxLinks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Custom Links',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: kDarkGrey,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '(${links.length}/$_kMaxLinks)',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                color: atMax ? Colors.redAccent : kDarkGrey,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...links.asMap().entries.map((entry) {
          final i = entry.key;
          final link = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: kLight,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Icon(Icons.link, size: 16.sp, color: kDarkGrey),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.label,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: kDark,
                        ),
                      ),
                      Text(
                        link.url,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 11.sp,
                          color: kDarkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _remove(i),
                  child: Icon(Icons.delete_outline,
                      size: 18.sp, color: Colors.redAccent),
                ),
              ],
            ),
          );
        }),
        if (!atMax) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: TextFormField(
              controller: _labelCtrl,
              maxLength: 50,
              style: TextStyle(
                  fontFamily: kFontDMSans, fontSize: 14.sp, color: kDark),
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. GitHub, Portfolio',
                errorText: _labelError,
                counterStyle:
                    TextStyle(fontSize: 10.sp, color: kDarkGrey),
                labelStyle: kSmallTextStyle.copyWith(
                    color: kDarkGrey, fontSize: 13.sp),
                hintStyle: kSmallTextStyle.copyWith(
                    color: const Color(0xFFBBBBBB), fontSize: 13.sp),
                filled: true,
                fillColor: kLight,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 14.h),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: kLightGrey)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: kLightGrey)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(
                        color: kThemeColor, width: 1.5)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              maxLength: 200,
              style: TextStyle(
                  fontFamily: kFontDMSans, fontSize: 14.sp, color: kDark),
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://',
                errorText: _urlError,
                counterStyle:
                    TextStyle(fontSize: 10.sp, color: kDarkGrey),
                labelStyle: kSmallTextStyle.copyWith(
                    color: kDarkGrey, fontSize: 13.sp),
                hintStyle: kSmallTextStyle.copyWith(
                    color: const Color(0xFFBBBBBB), fontSize: 13.sp),
                filled: true,
                fillColor: kLight,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 14.h),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: kLightGrey)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: kLightGrey)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(
                        color: kThemeColor, width: 1.5)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, color: kThemeColor, size: 18),
              label: Text(
                'ADD LINK',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: kThemeColor,
                ),
              ),
            ),
          ),
        ] else
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
            child: Text(
              'Maximum $_kMaxLinks links reached.',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                color: kDarkGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Add Button ────────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: kThemeColor,
            side: const BorderSide(color: kThemeColor),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            textStyle: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gender Selector ───────────────────────────────────────────────────────────
class _GenderSelector extends StatefulWidget {
  const _GenderSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<_GenderSelector> {
  late String _selected;
  static const _options = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: kDarkGrey,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _options.map((opt) {
            final active = _selected == opt;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = opt);
                widget.onChanged(opt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: active ? kThemeColor : kLight,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: active ? kThemeColor : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 13.sp,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? kLight : kDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── DOB Date Picker ───────────────────────────────────────────────────────────
class _DOBPicker extends StatefulWidget {
  const _DOBPicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_DOBPicker> createState() => _DOBPickerState();
}

class _DOBPickerState extends State<_DOBPicker> {
  late String _display;

  @override
  void initState() {
    super.initState();
    _display = _format(widget.value);
  }

  String _format(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _pick() async {
    DateTime initial = DateTime(2000);
    try {
      if (widget.value.isNotEmpty) initial = DateTime.parse(widget.value);
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kThemeColor),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final iso = picked.toIso8601String().split('T').first;
    setState(() => _display = _format(iso));
    widget.onChanged(iso);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: kLight,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 18.sp, color: kDarkGrey),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _display.isEmpty ? 'Date of Birth' : _display,
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 14.sp,
                  color: _display.isEmpty
                      ? const Color(0xFFBBBBBB)
                      : kDark,
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 16.sp, color: kDarkGrey),
          ],
        ),
      ),
    );
  }
}

// ── Option Selector ───────────────────────────────────────────────────────────
class _OptionSelector extends StatefulWidget {
  const _OptionSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_OptionSelector> createState() => _OptionSelectorState();
}

class _OptionSelectorState extends State<_OptionSelector> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: kDarkGrey,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.options.map((opt) {
            final active = _selected == opt;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = opt);
                widget.onChanged(opt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: active ? kThemeColor : kLight,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: active ? kThemeColor : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 13.sp,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? kLight : kDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Date Range Picker ─────────────────────────────────────────────────────────
class _DateRangePicker extends StatefulWidget {
  const _DateRangePicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<_DateRangePicker> {
  String _from = '';
  String _to = '';
  bool _isPresent = false;

  @override
  void initState() {
    super.initState();
    _parse(widget.value);
  }

  void _parse(String value) {
    if (value.isEmpty) return;
    final parts = value.split(' - ');
    _from = parts[0].trim();
    if (parts.length > 1) {
      _isPresent = parts[1].trim().toLowerCase() == 'present';
      _to = _isPresent ? '' : parts[1].trim();
    }
  }

  String _combined() {
    if (_from.isEmpty) return '';
    if (_isPresent) return '$_from - Present';
    if (_to.isNotEmpty) return '$_from - $_to';
    return _from;
  }

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kThemeColor),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _from = _fmt(picked));
    widget.onChanged(_combined());
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kThemeColor),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _to = _fmt(picked);
      _isPresent = false;
    });
    widget.onChanged(_combined());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration',
            style: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: kDarkGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _dateTile(
                    label: 'From', value: _from, onTap: _pickFrom),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _dateTile(
                  label: 'To',
                  value: _isPresent ? 'Present' : _to,
                  isPresent: _isPresent,
                  onTap: _isPresent ? null : _pickTo,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          InkWell(
            borderRadius: BorderRadius.circular(6.r),
            onTap: () {
              setState(() {
                _isPresent = !_isPresent;
                if (_isPresent) _to = '';
              });
              widget.onChanged(_combined());
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _isPresent,
                  onChanged: (v) {
                    setState(() {
                      _isPresent = v ?? false;
                      if (_isPresent) _to = '';
                    });
                    widget.onChanged(_combined());
                  },
                  activeColor: kThemeColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Currently working here',
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 12.sp,
                    color: kDarkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    bool isPresent = false,
    VoidCallback? onTap,
  }) {
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isPresent ? kBackgroundColor : kLight,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isPresent
                ? kThemeColor.withValues(alpha: 0.5)
                : kLightGrey,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 10.sp,
                color: kDarkGrey,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12.sp,
                  color: isPresent ? kThemeColor : kDarkGrey,
                ),
                SizedBox(width: 4.w),
                Text(
                  hasValue ? value : 'Tap to set',
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 13.sp,
                    color: isPresent
                        ? kThemeColor
                        : (hasValue ? kDark : const Color(0xFFBBBBBB)),
                    fontWeight: isPresent
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}