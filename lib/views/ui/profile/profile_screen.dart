import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:provider/provider.dart';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proco/models/request/auth/professional_items.dart';
import 'profile_edit.dart';
import 'profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditState(),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          drawer: const LagoonDrawer(),
          appBar: const LagoonAppBar(),
          body: Consumer<ProfileEditState>(
            builder: (context, state, _) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: kThemeColor),
                );
              }

              if (state.error != null) {
                return _ErrorView(state: state);
              }

              return Column(
                children: [
                  _ProfileTabBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _AboutTab(state: state),
                        _PersonalTab(state: state),
                        _ProfessionalTab(state: state),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: kDark,
        unselectedLabelColor: kDarkGrey,
        indicatorColor: kDark,
        indicatorWeight: 2.5,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
        labelStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Personal'),
          Tab(text: 'Professional'),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.state});
  final ProfileEditState state;

  @override
  Widget build(BuildContext context) {
    final location = [state.city, state.state, state.country]
        .where((s) => s.isNotEmpty)
        .join(', ');

    final bio = _composeBio();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 32.h),
      child: Column(
        children: [
          _AvatarWithBadge(imageUrl: state.profileImageUrl),
          SizedBox(height: 14.h),
          Text(
            state.username.isEmpty ? 'Your Name' : state.username,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: kDark,
            ),
          ),
          SizedBox(height: 5.h),
          if (location.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 14.sp, color: kDarkGrey),
                SizedBox(width: 3.w),
                Text(
                  location,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13.sp,
                    color: kDarkGrey,
                  ),
                ),
              ],
            ),
          SizedBox(height: 22.h),
          if (bio.isNotEmpty)
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14.sp,
                color: kDark,
                height: 1.55,
              ),
            )
          else if (location.isEmpty)
            const _EmptyStateText(),
          SizedBox(height: 28.h),
          Row(
            children: [
              Expanded(child: _StatCard(value: '${state.queriesCreated}', label: 'QUERIES\nCREATED')),
              SizedBox(width: 14.w),
              Expanded(
                child: _StatCard(value: '0', label: 'SUCCESSFUL\nMATCHES'),
              ),
            ],
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const EditProfilePage()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kThemeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'EDIT PROFILE',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: kLight,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _composeBio() {
    final parts = <String>[];
    if (state.college.isNotEmpty) parts.add(state.college);
    if (state.branch.isNotEmpty) parts.add(state.branch);
    if (state.interests.isNotEmpty) parts.addAll(state.interests.take(3));
    return parts.join(' · ');
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88.w,
          height: 88.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE0E0E0),
          ),
          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kThemeColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 42.sp,
                      color: kDarkGrey,
                    ),
                  )
                : Icon(Icons.person, size: 42.sp, color: kDarkGrey),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 26.w,
            height: 26.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kTeal,
            ),
            child: Icon(Icons.check, size: 14.sp, color: kLight),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: kDark,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: kDarkGrey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.state});
  final ProfileEditState state;

  int _calculateAge() {
    if (state.dob.isEmpty) return 0;
    try {
      final birth = DateTime.parse(state.dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge();
    final hasGender = state.gender.isNotEmpty;
    final hasAge = age > 0;
    final hasEducation = state.college.isNotEmpty || state.branch.isNotEmpty;
    final hasInterests = state.interests.isNotEmpty || state.hobbies.isNotEmpty;

    final links = <({String label, String url})>[];
    if (state.linkedInUrl.isNotEmpty) links.add((label: 'LINKEDIN', url: state.linkedInUrl));
    if (state.gitHubUrl.isNotEmpty) links.add((label: 'GITHUB', url: state.gitHubUrl));
    if (state.twitterUrl.isNotEmpty) links.add((label: 'TWITTER / X', url: state.twitterUrl));
    if (state.portfolioUrl.isNotEmpty) links.add((label: 'PORTFOLIO', url: state.portfolioUrl));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfidentialCard(email: state.email, phone: state.phone),
          if (hasGender || hasAge) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                if (hasGender)
                  Expanded(child: _InfoTile(label: 'GENDER', value: state.gender)),
                if (hasGender && hasAge) SizedBox(width: 12.w),
                if (hasAge)
                  Expanded(child: _InfoTile(label: 'AGE', value: '$age')),
              ],
            ),
          ],
          if (hasEducation) ...[
            SizedBox(height: 24.h),
            _SectionHeader(title: 'EDUCATION', icon: Icons.school_outlined),
            SizedBox(height: 12.h),
            _EducationCard(state: state),
          ],
          if (hasInterests) ...[
            SizedBox(height: 24.h),
            const _CapLabel('INTERESTS & HOBBIES'),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                ...state.interests.map((i) => _OutlineChip(label: i)),
                ...state.hobbies.map((h) => _OutlineChip(label: h)),
              ],
            ),
          ],
          if (links.isNotEmpty) ...[
            SizedBox(height: 24.h),
            const _CapLabel('EXTERNAL LINKS'),
            SizedBox(height: 12.h),
            ...links.map(
              (l) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _LinkRow(label: l.label),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Professional tab ───────────────────────────────────────────────────────

class _ProfessionalTab extends StatefulWidget {
  const _ProfessionalTab({required this.state});
  final ProfileEditState state;

  @override
  State<_ProfessionalTab> createState() => _ProfessionalTabState();
}

class _ProfessionalTabState extends State<_ProfessionalTab> {
  ProfileEditState get _s => widget.state;

  Future<void> _save() async {
    final ok = await _s.saveProfile(null);
    if (!mounted) return;
    if (ok) {
      Get.snackbar('Saved', 'Professional info updated.',
          backgroundColor: kTeal,
          colorText: kLight,
          duration: const Duration(seconds: 3));
    } else {
      Get.snackbar('Error', 'Could not save changes.',
          backgroundColor: kOrange, colorText: kLight);
    }
  }

  void _addExperience(ExperienceItem exp) {
    setState(() => _s.experiences = [..._s.experiences, exp]);
    _save();
  }

  void _removeExperience(int index) {
    setState(() => _s.experiences = List.from(_s.experiences)..removeAt(index));
    _save();
  }

  void _addProject(ProjectItem proj) {
    setState(() => _s.projects = [..._s.projects, proj]);
    _save();
  }

  void _removeProject(int index) {
    setState(() => _s.projects = List.from(_s.projects)..removeAt(index));
    _save();
  }

  void _addAchievement(AchievementItem ach) {
    setState(() => _s.achievements = [..._s.achievements, ach]);
    _save();
  }

  void _removeAchievement(int index) {
    setState(
        () => _s.achievements = List.from(_s.achievements)..removeAt(index));
    _save();
  }

  void _showSheet(Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProSectionHeader(
            title: 'EXPERIENCE',
            icon: Icons.work_outline,
            onAdd: () => _showSheet(_AddExperienceSheet(onAdd: _addExperience)),
          ),
          SizedBox(height: 18.h),
          if (_s.experiences.isEmpty)
            const _EmptySection(label: 'No experience added yet')
          else
            ..._s.experiences.asMap().entries.map(
                  (e) => _ExperienceRow(
                    data: e.value,
                    onDelete: () => _removeExperience(e.key),
                  ),
                ),
          SizedBox(height: 28.h),
          _ProSectionHeader(
            title: 'PROJECT SHOWCASE',
            icon: Icons.star_border,
            onAdd: () => _showSheet(_AddProjectSheet(onAdd: _addProject)),
          ),
          SizedBox(height: 18.h),
          if (_s.projects.isEmpty)
            const _EmptySection(label: 'No projects added yet')
          else
            ..._s.projects.asMap().entries.map(
                  (p) => _ProjectCard(
                    data: p.value,
                    onDelete: () => _removeProject(p.key),
                  ),
                ),
          SizedBox(height: 28.h),
          _ProSectionHeader(
            title: 'ACHIEVEMENTS',
            icon: Icons.emoji_events_outlined,
            onAdd: () =>
                _showSheet(_AddAchievementSheet(onAdd: _addAchievement)),
          ),
          SizedBox(height: 18.h),
          if (_s.achievements.isEmpty)
            const _EmptySection(label: 'No achievements added yet')
          else
            ..._s.achievements.asMap().entries.map(
                  (a) => _AchievementRow(
                    data: a.value,
                    onDelete: () => _removeAchievement(a.key),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Professional section header ────────────────────────────────────────────

class _ProSectionHeader extends StatelessWidget {
  const _ProSectionHeader({
    required this.title,
    required this.icon,
    this.onAdd,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: kDarkGrey, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: kDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: kThemeColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.add, color: kLight, size: 18.sp),
            ),
          ),
      ],
    );
  }
}

// ── Experience row ─────────────────────────────────────────────────────────

class _ExperienceRow extends StatelessWidget {
  const _ExperienceRow({required this.data, required this.onDelete});
  final ExperienceItem data;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: kDark),
            child: Center(
              child: Text(
                data.company.isEmpty ? '?' : data.company[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: kLight,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data.company,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: kDark,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      data.dateRange,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 10.sp,
                        color: kDarkGrey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  data.position,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12.sp,
                    color: kDarkGrey,
                  ),
                ),
                if (data.description.isNotEmpty) ...[
                  SizedBox(height: 5.h),
                  Text(
                    data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.sp,
                      color: kDarkGrey,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline, size: 18.sp, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

// ── Project card ───────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.data, required this.onDelete});
  final ProjectItem data;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark preview card with domain badge + delete button
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 150.h,
                decoration: BoxDecoration(
                  color: kDarkBlue,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: kThemeColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      data.domain.isEmpty ? 'Project' : data.domain,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: kLight,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child:
                        Icon(Icons.delete_outline, size: 16.sp, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Project name
          Text(
            data.name,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: kDark,
            ),
          ),
          SizedBox(height: 6.h),

          // Description (max 2 lines)
          if (data.description.isNotEmpty) ...[
            Text(
              data.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13.sp,
                color: kDarkGrey,
                height: 1.5,
              ),
            ),
            SizedBox(height: 10.h),
          ],

          // Technology chips
          if (data.technologies.isNotEmpty) ...[
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children:
                  data.technologies.map((t) => _TechChip(label: t)).toList(),
            ),
            SizedBox(height: 12.h),
          ],

          // Clickable project link
          if (data.sourceUrl.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(data.sourceUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 14.sp, color: kThemeColor),
                  SizedBox(width: 6.w),
                  Text(
                    'VIEW PROJECT',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: kThemeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: kDarkGrey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Achievement row ────────────────────────────────────────────────────────

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.data, required this.onDelete});
  final AchievementItem data;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_outlined, size: 22.sp, color: kDark),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: kDark,
                  ),
                ),
                if (data.subtitle.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: kDarkGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline, size: 18.sp, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

// ── Empty section placeholder ──────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 13.sp,
          color: kDarkGrey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Shared sheet text field ────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboard,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(fontFamily: 'DMSans', fontSize: 14.sp, color: kDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontFamily: 'DMSans', fontSize: 13.sp, color: kDarkGrey),
        hintStyle: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13.sp,
            color: const Color(0xFFBBBBBB)),
        filled: true,
        fillColor: kBackgroundColor,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: kThemeColor, width: 1.5),
        ),
      ),
    );
  }
}

// ── Add Experience sheet ───────────────────────────────────────────────────

class _AddExperienceSheet extends StatefulWidget {
  const _AddExperienceSheet({required this.onAdd});
  final void Function(ExperienceItem) onAdd;

  @override
  State<_AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<_AddExperienceSheet> {
  final _company = TextEditingController();
  final _position = TextEditingController();
  final _description = TextEditingController();
  final _dateRange = TextEditingController();

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _description.dispose();
    _dateRange.dispose();
    super.dispose();
  }

  void _submit() {
    if (_company.text.trim().isEmpty || _position.text.trim().isEmpty) return;
    widget.onAdd(ExperienceItem(
      company: _company.text.trim(),
      position: _position.text.trim(),
      description: _description.text.trim(),
      dateRange: _dateRange.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Experience',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kDark)),
          SizedBox(height: 20.h),
          _SheetField(label: 'Company *', controller: _company),
          SizedBox(height: 12.h),
          _SheetField(label: 'Position / Role *', controller: _position),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Description',
              controller: _description,
              maxLines: 2),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Date Range',
              controller: _dateRange,
              hint: '2022 – 2024'),
          SizedBox(height: 20.h),
          _SheetAddButton(onPressed: _submit),
        ],
      ),
    );
  }
}

// ── Add Project sheet ──────────────────────────────────────────────────────

class _AddProjectSheet extends StatefulWidget {
  const _AddProjectSheet({required this.onAdd});
  final void Function(ProjectItem) onAdd;

  @override
  State<_AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<_AddProjectSheet> {
  final _name = TextEditingController();
  final _domain = TextEditingController();
  final _description = TextEditingController();
  final _techs = TextEditingController();
  final _url = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _domain.dispose();
    _description.dispose();
    _techs.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final techList = _techs.text
        .split(',')
        .map((t) => t.trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toList();
    widget.onAdd(ProjectItem(
      name: _name.text.trim(),
      domain: _domain.text.trim(),
      description: _description.text.trim(),
      technologies: techList,
      sourceUrl: _url.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Project',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kDark)),
          SizedBox(height: 20.h),
          _SheetField(label: 'Project Name *', controller: _name),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Domain / Category',
              controller: _domain,
              hint: 'e.g. App Development'),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Description (1-2 lines)',
              controller: _description,
              maxLines: 2),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Skills / Technologies (comma-separated)',
              controller: _techs,
              hint: 'Flutter, Firebase, Node.js'),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Project Link / URL',
              controller: _url,
              keyboard: TextInputType.url),
          SizedBox(height: 20.h),
          _SheetAddButton(onPressed: _submit),
        ],
      ),
    );
  }
}

// ── Add Achievement sheet ──────────────────────────────────────────────────

class _AddAchievementSheet extends StatefulWidget {
  const _AddAchievementSheet({required this.onAdd});
  final void Function(AchievementItem) onAdd;

  @override
  State<_AddAchievementSheet> createState() => _AddAchievementSheetState();
}

class _AddAchievementSheetState extends State<_AddAchievementSheet> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    widget.onAdd(AchievementItem(
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 24.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Achievement',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: kDark)),
          SizedBox(height: 20.h),
          _SheetField(label: 'Title *', controller: _title),
          SizedBox(height: 12.h),
          _SheetField(
              label: 'Subtitle',
              controller: _subtitle,
              hint: 'CERT LEVEL • 2025'),
          SizedBox(height: 20.h),
          _SheetAddButton(onPressed: _submit),
        ],
      ),
    );
  }
}

// ── Shared ADD button for sheets ───────────────────────────────────────────

class _SheetAddButton extends StatelessWidget {
  const _SheetAddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kThemeColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: kLight,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Text(
          'User has not added any data',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13.sp,
            fontStyle: FontStyle.italic,
            color: kDarkGrey,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.state});
  final ProfileEditState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          SizedBox(height: 10.h),
          Text(
            state.error!,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14.sp,
              color: kDark,
            ),
          ),
          TextButton(
            onPressed: () => state.loadProfile(),
            child: const Text(
              'Retry',
              style: TextStyle(color: kThemeColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confidential card ──────────────────────────────────────────────────────

class _ConfidentialCard extends StatelessWidget {
  const _ConfidentialCard({required this.email, required this.phone});
  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kDarkBlue,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIDENTIAL',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: kLight,
                    ),
                  ),
                ],
              ),
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.white60,
                  size: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'EMAIL',
            value: email.isEmpty ? 'Not provided' : email,
          ),
          SizedBox(height: 14.h),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'PHONE NO.',
            value: phone.isEmpty ? 'Not provided' : phone,
          ),
          SizedBox(height: 18.h),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 12.sp, color: Colors.white38),
              SizedBox(width: 6.w),
              Text(
                'PRIVATE ACCESS ONLY',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Icon(icon, color: Colors.white70, size: 20.sp),
        ),
        SizedBox(width: 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: kLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Gender / Age tile ──────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: kDarkGrey,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: kDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Education ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: kDark,
            letterSpacing: 0.5,
          ),
        ),
        Icon(icon, color: kDarkGrey, size: 22.sp),
      ],
    );
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.state});
  final ProfileEditState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EduField(
            label: 'INSTITUTION',
            value: state.college.isEmpty ? '—' : state.college,
            valueFontSize: 18.sp,
          ),
          SizedBox(height: 16.h),
          _EduField(
            label: 'FIELD OF STUDY',
            value: state.branch.isEmpty ? '—' : state.branch,
            valueFontSize: 15.sp,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _EduField(
                  label: 'GRADUATION',
                  value: '—',
                  valueFontSize: 15.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _EduField(
                  label: 'ACADEMIC RANK',
                  value: '—',
                  valueFontSize: 15.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EduField extends StatelessWidget {
  const _EduField({
    required this.label,
    required this.value,
    required this.valueFontSize,
  });
  final String label;
  final String value;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: kDarkGrey,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: kDark,
          ),
        ),
      ],
    );
  }
}

// ── Small caps label ───────────────────────────────────────────────────────

class _CapLabel extends StatelessWidget {
  const _CapLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: kDarkGrey,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Chips ──────────────────────────────────────────────────────────────────

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
          color: kDark,
        ),
      ),
    );
  }
}

// ── External links ─────────────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: kLight,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.language_outlined, size: 18.sp, color: kDark),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: kDark,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
