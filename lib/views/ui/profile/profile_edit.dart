import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/phone_field.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:provider/provider.dart';
import 'profile_state.dart';

const int _kMaxLinks = 6;

// ── Section keys for scroll-to ────────────────────────────────────────────────
final _identityKey = GlobalKey();
final _personalKey = GlobalKey();
final _educationKey = GlobalKey();
final _professionalKey = GlobalKey();
final _attributesKey = GlobalKey();

const _tabs = [
  'Identity',
  'Personal',
  'Education',
  'Professional',
  'Attributes',
];
final _sectionKeys = <GlobalKey>[
  _identityKey,
  _personalKey,
  _educationKey,
  _professionalKey,
  _attributesKey,
];

// ── Page ─────────────────────────────────────────────────────────────────────
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
                          letterSpacing: 1.2,
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

// ── EditForm with sticky navbar ───────────────────────────────────────────────
class _EditForm extends StatefulWidget {
  const _EditForm({required this.state});
  final ProfileEditState state;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final ScrollController _scrollController = ScrollController();
  int _activeTab = 0;
  bool _isScrollingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isScrollingProgrammatically) return;
    int nearest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      final dist = (pos.dy - 120).abs();
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }
    if (_activeTab != nearest) {
      setState(() => _activeTab = nearest);
    }
  }

  Future<void> _scrollToSection(int index) async {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    setState(() {
      _activeTab = index;
      _isScrollingProgrammatically = true;
    });
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
    await Future.delayed(const Duration(milliseconds: 450));
    _isScrollingProgrammatically = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StickyNavbar(activeIndex: _activeTab, onTabTapped: _scrollToSection),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
            children: [
              // Identity
              _SectionTitle(key: _identityKey, title: 'Identity'),
              _IdentitySection(state: widget.state),
              SizedBox(height: 20.h),

              // Personal
              _SectionTitle(key: _personalKey, title: 'Personal'),
              PhoneInputField(
                initialValue: widget.state.phone,
                onChanged: (v) => widget.state.phone = v,
              ),
              SizedBox(height: 10.h),
              _Field(
                label: 'Gender',
                init: widget.state.gender,
                onChanged: (v) => widget.state.gender = v,
              ),
              _Field(
                label: 'Date of Birth',
                init: widget.state.dob,
                onChanged: (v) => widget.state.dob = v,
                hint: 'YYYY-MM-DD',
              ),
              _Field(
                label: 'Work Style',
                init: widget.state.workStyle,
                onChanged: (v) => widget.state.workStyle = v,
                hint: 'e.g. Remote-first, Hybrid, In-office',
              ),
              _Field(
                label: 'Communication Style',
                init: widget.state.communicationStyle,
                onChanged: (v) => widget.state.communicationStyle = v,
                hint: 'e.g. Asynchronous, Synchronous',
              ),
              SizedBox(height: 6.h),
              _LinksEditor(state: widget.state),
              SizedBox(height: 20.h),

              // Education
              _SectionTitle(key: _educationKey, title: 'Education'),
              _Field(
                label: 'Institution / College',
                init: widget.state.college,
                onChanged: (v) => widget.state.college = v,
              ),
              _Field(
                label: 'Degree / Branch',
                init: widget.state.branch,
                onChanged: (v) => widget.state.branch = v,
              ),
              _Field(
                label: 'Class of (Graduation Year)',
                init: widget.state.classOf,
                onChanged: (v) => widget.state.classOf = v,
                hint: 'e.g. 2025',
                keyboard: TextInputType.number,
              ),
              _Field(
                label: 'CGPA / Academic Rank',
                init: widget.state.cgpa,
                onChanged: (v) => widget.state.cgpa = v,
                hint: 'e.g. 8.5 or 3.9/4.0',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 20.h),

              // Professional
              _SectionTitle(key: _professionalKey, title: 'Professional'),

              // Experience Section
              ...widget.state.experiences.asMap().entries.map((entry) {
                int index = entry.key;
                ExperienceItem exp = entry.value;

                return _ExpandableSection(
                  sectionLabel: exp.company.isEmpty
                      ? 'New Experience'
                      : exp.company,
                  icon: Icons.work_outline,
                  initiallyExpanded: exp.company.isEmpty,
                  children: [
                    _Field(
                      label: 'Company *',
                      init: exp.company,
                      onChanged: (val) {
                        widget.state.updateExperience(index, ExperienceItem(
                          company: val,
                          position: exp.position,
                          description: exp.description,
                          dateRange: exp.dateRange,
                        ));
                      },
                    ),
                    _Field(
                      label: 'Job Title / Role *',
                      init: exp.position,
                      onChanged: (val) {
                        widget.state.updateExperience(index, ExperienceItem(
                          company: exp.company,
                          position: val,
                          description: exp.description,
                          dateRange: exp.dateRange,
                        ));
                      },
                    ),
                    _Field(
                      label: 'Description',
                      init: exp.description,
                      onChanged: (val) {
                        widget.state.updateExperience(index, ExperienceItem(
                          company: exp.company,
                          position: exp.position,
                          description: val,
                          dateRange: exp.dateRange,
                        ));
                      },
                      maxLines: 3,
                      hint: 'Describe your role and impact…',
                    ),
                    _DateRangePicker(
                      value: exp.dateRange,
                      onChanged: (val) {
                        widget.state.updateExperience(index, ExperienceItem(
                          company: exp.company,
                          position: exp.position,
                          description: exp.description,
                          dateRange: val,
                        ));
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => widget.state.removeExperience(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                );
              }),

              // Add Experience Button
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: OutlinedButton.icon(
                  onPressed: () {
                    final exps = widget.state.experiences;
                    if (exps.isNotEmpty) {
                      final last = exps.last;
                      if (last.company.trim().isEmpty || last.position.trim().isEmpty) {
                        Get.snackbar(
                          'Fill required fields',
                          'Complete the current experience (company & role) before adding another.',
                          backgroundColor: kOrange,
                          colorText: kLight,
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }
                    }
                    widget.state.addExperience(
                      ExperienceItem(company: '', position: '', description: '', dateRange: ''),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('ADD EXPERIENCE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kThemeColor,
                    side: const BorderSide(color: kThemeColor),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Projects Section
              ...widget.state.projects.asMap().entries.map((entry) {
                int index = entry.key;
                ProjectItem proj = entry.value;

                return _ExpandableSection(
                  sectionLabel: proj.name.isEmpty ? 'New Project' : proj.name,
                  icon: Icons.code_outlined,
                  initiallyExpanded: proj.name.isEmpty,
                  children: [
                    _Field(
                      label: 'Project Name *',
                      init: proj.name,
                      onChanged: (val) {
                        widget.state.updateProject(index, ProjectItem(
                          name: val,
                          domain: proj.domain,
                          description: proj.description,
                          technologies: proj.technologies,
                          sourceUrl: proj.sourceUrl,
                        ));
                      },
                    ),
                    _Field(
                      label: 'Description',
                      init: proj.description,
                      onChanged: (val) {
                        widget.state.updateProject(index, ProjectItem(
                          name: proj.name,
                          domain: proj.domain,
                          description: val,
                          technologies: proj.technologies,
                          sourceUrl: proj.sourceUrl,
                        ));
                      },
                      maxLines: 3,
                      hint: 'What does this project do?',
                    ),
                    _Field(
                      label: 'Skills / Technologies',
                      init: proj.technologies.join(', '),
                      onChanged: (val) {
                        final techs = val
                            .split(',')
                            .map((t) => t.trim().toUpperCase())
                            .where((t) => t.isNotEmpty)
                            .toList();
                        widget.state.updateProject(index, ProjectItem(
                          name: proj.name,
                          domain: proj.domain,
                          description: proj.description,
                          technologies: techs,
                          sourceUrl: proj.sourceUrl,
                        ));
                      },
                      hint: 'Flutter, Firebase, Node.js (comma-separated)',
                    ),
                    _Field(
                      label: 'Source Code / Live Link',
                      init: proj.sourceUrl,
                      onChanged: (val) {
                        widget.state.updateProject(index, ProjectItem(
                          name: proj.name,
                          domain: proj.domain,
                          description: proj.description,
                          technologies: proj.technologies,
                          sourceUrl: val,
                        ));
                      },
                      hint: 'https://github.com/…',
                      keyboard: TextInputType.url,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => widget.state.removeProject(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                );
              }),

              // Add Project Button
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: OutlinedButton.icon(
                  onPressed: () {
                    final projs = widget.state.projects;
                    if (projs.isNotEmpty && projs.last.name.trim().isEmpty) {
                      Get.snackbar(
                        'Fill required fields',
                        'Complete the current project (name) before adding another.',
                        backgroundColor: kOrange,
                        colorText: kLight,
                        snackPosition: SnackPosition.TOP,
                      );
                      return;
                    }
                    widget.state.addProject(
                      ProjectItem(name: '', domain: '', description: '', technologies: [], sourceUrl: ''),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('ADD PROJECT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kThemeColor,
                    side: const BorderSide(color: kThemeColor),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // ── Achievements Loop ──────────────────────────────────────────────────────
              ...widget.state.achievements.asMap().entries.map((entry) {
                int index = entry.key;
                AchievementItem ach = entry.value;

                return _ExpandableSection(
                  sectionLabel: ach.title.isEmpty
                      ? 'New Achievement'
                      : ach.title,
                  icon: Icons.emoji_events_outlined,
                  children: [
                    _Field(
                      label: 'Title',
                      init: ach.title,
                      onChanged: (val) {
                        widget.state.updateAchievement(index, AchievementItem(
                          title: val,
                          subtitle: ach.subtitle,
                          icon: ach.icon,
                        ));
                      },
                      hint: 'e.g. Hackathon Winner',
                    ),
                    _Field(
                      label: 'Subtitle / Description',
                      init: ach.subtitle,
                      onChanged: (val) {
                        widget.state.updateAchievement(index, AchievementItem(
                          title: ach.title,
                          subtitle: val,
                          icon: ach.icon,
                        ));
                      },
                      hint: 'e.g. Secured 1st rank among 50 teams',
                    ),
                    _Field(
                      label: 'Icon Name',
                      init: ach.icon,
                      onChanged: (val) {
                        widget.state.updateAchievement(index, AchievementItem(
                          title: ach.title,
                          subtitle: ach.subtitle,
                          icon: val,
                        ));
                      },
                      hint: 'e.g. star, military_tech, trophy',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => widget.state.removeAchievement(index),
                      ),
                    ),
                  ],
                );
              }),

              // Add Achievement Button
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: TextButton.icon(
                  onPressed: () {
                    widget.state.addAchievement(
                      AchievementItem(
                        title: '',
                        subtitle: '',
                        icon: 'star', // Default icon
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: kThemeColor),
                  label: const Text(
                    'ADD ACHIEVEMENT',
                    style: TextStyle(color: kThemeColor),
                  ),
                ),
              ),

              _Field(
                label: 'LinkedIn URL',
                init: widget.state.linkedInUrl,
                onChanged: (v) => widget.state.linkedInUrl = v,
                keyboard: TextInputType.url,
              ),
              _Field(
                label: 'GitHub URL',
                init: widget.state.gitHubUrl,
                onChanged: (v) => widget.state.gitHubUrl = v,
                keyboard: TextInputType.url,
              ),
              _Field(
                label: 'Twitter / X URL',
                init: widget.state.twitterUrl,
                onChanged: (v) => widget.state.twitterUrl = v,
                keyboard: TextInputType.url,
              ),
              _Field(
                label: 'Portfolio / Behance URL',
                init: widget.state.portfolioUrl,
                onChanged: (v) => widget.state.portfolioUrl = v,
                keyboard: TextInputType.url,
              ),
              SizedBox(height: 20.h),

              // Attributes
              _SectionTitle(key: _attributesKey, title: 'Attributes'),
              _ChipInputSection(
                label: 'Skills',
                values: widget.state.skills,
                onAdded: (v) => widget.state.addSkill(v),
                onRemoved: (v) => widget.state.removeSkill(v),
              ),
              SizedBox(height: 14.h),
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

// ── Sticky Navbar ─────────────────────────────────────────────────────────────
class _StickyNavbar extends StatelessWidget {
  const _StickyNavbar({required this.activeIndex, required this.onTabTapped});

  final int activeIndex;
  final ValueChanged<int> onTabTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isActive = i == activeIndex;
            return GestureDetector(
              onTap: () => onTabTapped(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? kThemeColor : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 13.sp,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? kDark : kDarkGrey,
                  ),
                ),
              ),
            );
          }),
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
                  onTap: () {
                    // Logic for image picking can be handled in state
                  },
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
        _Field(
          label: 'Full Name',
          init: state.username,
          onChanged: (v) => state.username = v,
        ),
        _BioField(
          init: state.bio,
          onChanged: (v) => state.bio = v,
        ),
        _Field(
          label: 'City',
          init: state.city,
          onChanged: (v) => state.city = v,
        ),
        _Field(
          label: 'State',
          init: state.state,
          onChanged: (v) => state.state = v,
        ),
        _Field(
          label: 'Country',
          init: state.country,
          onChanged: (v) => state.country = v,
        ),
      ],
    );
  }
}

// ── Expandable Professional Tile ─────────────────────────────────────────────
class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.sectionLabel,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String sectionLabel;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: kLightGrey),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: _toggle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18.r, color: kThemeColor),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.sectionLabel,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: kDark,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.edit,
                    size: 16.r,
                    color: _expanded ? kThemeColor : kDarkGrey,
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(children: widget.children),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip Input Section ────────────────────────────────────────────────────────
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final val = _controller.text.trim();
    if (val.isEmpty) return;
    widget.onAdded(val);
    _controller.clear();
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
                    fontFamily: kFontDMSans,
                    fontSize: 12.sp,
                    color: kDark,
                  ),
                ),
                backgroundColor: kLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: const BorderSide(color: kLightGrey),
                ),
                deleteIcon: Icon(Icons.close, size: 14.r, color: kDarkGrey),
                onDeleted: () => widget.onRemoved(v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              );
            }).toList(),
          ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 13.sp,
                  color: kDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Add ${widget.label.toLowerCase()}…',
                  hintStyle: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 13.sp,
                    color: const Color(0xFFBBBBBB),
                  ),
                  filled: true,
                  fillColor: kLight,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
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
                      color: kThemeColor,
                      width: 1.5,
                    ),
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
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h, top: 4.h),
      child: Text(
        title.toUpperCase(),
        style: kHeadingStyle.copyWith(
          fontSize: 11.sp,
          letterSpacing: 1.0,
          color: kDarkGrey,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.init,
    required this.onChanged,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
  });

  final String label;
  final String init;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        initialValue: init,
        keyboardType: keyboard,
        onChanged: onChanged,
        maxLines: maxLines,
        style: kSubTextStyle.copyWith(color: kDark, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: kSmallTextStyle.copyWith(
            color: kDarkGrey,
            fontSize: 13.sp,
          ),
          hintStyle: kSmallTextStyle.copyWith(
            color: const Color(0xFFBBBBBB),
            fontSize: 13.sp,
          ),
          filled: true,
          fillColor: kLight,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 14.h,
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
        ),
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
    final count = _countWords(value);
    if (count > _maxWords) {
      // Trim to 250 words
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
              labelStyle: kSmallTextStyle.copyWith(
                color: kDarkGrey,
                fontSize: 13.sp,
              ),
              hintStyle: kSmallTextStyle.copyWith(
                color: const Color(0xFFBBBBBB),
                fontSize: 13.sp,
              ),
              filled: true,
              fillColor: kLight,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 14.h,
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

// ── Links Editor ──────────────────────────────────────────────────────────────
class _LinksEditor extends StatefulWidget {
  const _LinksEditor({required this.state});
  final ProfileEditState state;

  @override
  State<_LinksEditor> createState() => _LinksEditorState();
}

class _LinksEditorState extends State<_LinksEditor> {
  final _labelCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final label = _labelCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (label.isEmpty || url.isEmpty) return;
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
        Text(
          'Links (${links.length}/$_kMaxLinks)',
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: kDarkGrey,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        ...links.asMap().entries.map((entry) {
          final i = entry.key;
          final link = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                  child: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          );
        }),
        if (!atMax) ...[
          SizedBox(height: 4.h),
          _Field(
            label: 'Label',
            init: '',
            onChanged: (v) => _labelCtrl.text = v,
            hint: 'e.g. GitHub, Portfolio, Behance',
          ),
          _Field(
            label: 'URL',
            init: '',
            onChanged: (v) => _urlCtrl.text = v,
            hint: 'https://',
            keyboard: TextInputType.url,
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
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
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
              Expanded(child: _dateTile(label: 'From', value: _from, onTap: _pickFrom)),
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
                    fontWeight: isPresent ? FontWeight.w600 : FontWeight.w400,
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
