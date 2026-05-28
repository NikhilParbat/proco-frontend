import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:provider/provider.dart';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'profile_edit.dart';
import 'profile_state.dart';

class ProfilePage extends StatelessWidget {
  final String? viewUserId;
  const ProfilePage({super.key, this.viewUserId});

  @override
  Widget build(BuildContext context) {
    final isReadOnly = viewUserId != null;

    return ChangeNotifierProvider(
      create: (_) => ProfileEditState(viewUserId: viewUserId),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          drawer: isReadOnly ? null : const LagoonDrawer(),
          appBar: isReadOnly
              ? AppBar(
                  backgroundColor: kThemeColor,
                  elevation: 0,
                  toolbarHeight: 50.h,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              : const LagoonAppBar(),
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
                        _PersonalTab(state: state, isReadOnly: isReadOnly),
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
    final location = [
      state.city,
      state.state,
      state.country,
    ].where((s) => s.isNotEmpty).join(', ');

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
              Expanded(
                child: _StatCard(
                  value: '${state.queriesCreated}',
                  label: 'QUERIES\nCREATED',
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _StatCard(
                  value: '${state.successfulMatches}',
                  label: 'SUCCESSFUL\nMATCHES',
                ),
              ),
            ],
          ),
          SizedBox(height: 28.h),
          if (!state.isReadOnly)
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

  String _composeBio() => state.bio;
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
                    errorWidget: (context, url, error) =>
                        Icon(Icons.person, size: 42.sp, color: kDarkGrey),
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
  const _PersonalTab({required this.state, required this.isReadOnly});
  final ProfileEditState state;
  final bool isReadOnly;

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
    final hasEducation = state.education.isNotEmpty;
    final hasWorkStyle = state.workStyle.isNotEmpty;
    final hasCommunicationStyle = state.communicationStyle.isNotEmpty;
    final hasSkills = state.skills.isNotEmpty;
    final hasLinks = state.links.isNotEmpty;
    final hasHobbies = state.hobbies.isNotEmpty;
    final hasInterests = state.interests.isNotEmpty;

    final hasAnyOptionalData = hasGender ||
        hasAge ||
        hasEducation ||
        hasWorkStyle ||
        hasCommunicationStyle ||
        hasSkills ||
        hasLinks ||
        hasHobbies ||
        hasInterests;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfidentialCard(
            email: state.email,
            phone: state.phone,
            isReadOnly: state.isReadOnly,
            isPrivateInfoVisible: state.isPrivateInfoVisible,
            onToggleVisibility: (newValue) {
              state.updatePrivacyPreference(newValue);
            },
          ),
          if (!hasAnyOptionalData) ...[
            SizedBox(height: 32.h),
            const _NoDataText(),
          ] else ...[
            if (hasGender || hasAge) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  if (hasGender)
                    Expanded(
                      child: _InfoTile(label: 'GENDER', value: state.gender),
                    ),
                  if (hasGender && hasAge) SizedBox(width: 12.w),
                  if (hasAge)
                    Expanded(
                      child: _InfoTile(label: 'AGE', value: '$age'),
                    ),
                ],
              ),
            ],
            if (hasEducation) ...[
              SizedBox(height: 24.h),
              _SectionHeader(title: 'EDUCATION', icon: Icons.school_outlined),
              SizedBox(height: 12.h),
              ...state.education.map(
                (edu) => Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: _EducationCard(item: edu),
                ),
              ),
            ],
            if (hasWorkStyle || hasCommunicationStyle) ...[
              SizedBox(height: 24.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasWorkStyle)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CapLabel('WORK STYLE'),
                          SizedBox(height: 8.h),
                          _OutlineChip(label: state.workStyle),
                        ],
                      ),
                    ),
                  if (hasWorkStyle && hasCommunicationStyle)
                    SizedBox(width: 16.w),
                  if (hasCommunicationStyle)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CapLabel('COMMUNICATION'),
                          SizedBox(height: 8.h),
                          _OutlineChip(label: state.communicationStyle),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (hasSkills) ...[
              SizedBox(height: 24.h),
              const _CapLabel('SKILLS'),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: state.skills.map((s) => _OutlineChip(label: s)).toList(),
              ),
            ],
            if (hasInterests) ...[
              SizedBox(height: 24.h),
              const _CapLabel('INTERESTS'),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: state.interests.map((i) => _OutlineChip(label: i)).toList(),
              ),
            ],
            if (hasHobbies) ...[
              SizedBox(height: 24.h),
              const _CapLabel('HOBBIES'),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: state.hobbies.map((h) => _OutlineChip(label: h)).toList(),
              ),
            ],
            if (hasLinks) ...[
              SizedBox(height: 24.h),
              const _CapLabel('EXTERNAL LINKS'),
              SizedBox(height: 12.h),
              ...state.links.map(
                (link) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _LinkRow(item: link),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final hasAnyData = _s.experiences.isNotEmpty ||
        _s.projects.isNotEmpty ||
        _s.achievements.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
      child: hasAnyData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_s.experiences.isNotEmpty) ...[
                  _ProSectionHeader(title: 'EXPERIENCE', icon: Icons.work_outline),
                  SizedBox(height: 18.h),
                  ..._s.experiences.asMap().entries.map(
                    (e) => _ExperienceRow(data: e.value),
                  ),
                  SizedBox(height: 28.h),
                ],
                if (_s.projects.isNotEmpty) ...[
                  _ProSectionHeader(
                    title: 'PROJECT SHOWCASE',
                    icon: Icons.star_border,
                  ),
                  SizedBox(height: 18.h),
                  ..._s.projects.asMap().entries.map(
                    (p) => _ProjectCard(data: p.value),
                  ),
                  SizedBox(height: 28.h),
                ],
                if (_s.achievements.isNotEmpty) ...[
                  _ProSectionHeader(
                    title: 'ACHIEVEMENTS',
                    icon: Icons.emoji_events_outlined,
                  ),
                  SizedBox(height: 18.h),
                  ..._s.achievements.asMap().entries.map(
                    (a) => _AchievementRow(data: a.value),
                  ),
                  SizedBox(height: 28.h),
                ],
              ],
            )
          : const _NoDataText(),
    );
  }
}

// ── Professional section header ────────────────────────────────────────────

class _ProSectionHeader extends StatelessWidget {
  const _ProSectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

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
      ],
    );
  }
}

// ── Experience row ─────────────────────────────────────────────────────────

class _ExperienceRow extends StatelessWidget {
  const _ExperienceRow({required this.data});
  final ExperienceItem data;

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kDark,
            ),
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
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.sp,
                      color: kDarkGrey,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Project card ───────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.data});
  final ProjectItem data;

  String _truncateWords(String text, int maxWords) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}…';
  }

  Future<void> _launch() async {
    final uri = Uri.tryParse(data.sourceUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _linkIcon() {
    final url = data.sourceUrl.toLowerCase();
    if (url.contains('github')) return Icons.code_rounded;
    if (url.contains('behance')) return Icons.brush_outlined;
    if (url.contains('dribbble')) return Icons.sports_basketball_outlined;
    return Icons.open_in_new;
  }

  @override
  Widget build(BuildContext context) {
    final techs = data.technologies.toList();
    final description = _truncateWords(data.description, 100);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: kLight,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top — kThemeColor, auto-height, project name only
                  Container(
                    width: double.infinity,
                    color: kThemeColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    child: Text(
                      data.name,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: kLight,
                      ),
                    ),
                  ),
                  // Bottom — white, description + techs + link
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.isNotEmpty) ...[
                          Text(
                            description,
                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 12.sp,
                              color: kDarkGrey,
                              height: 1.55,
                            ),
                          ),
                          SizedBox(height: 14.h),
                        ],
                        if (techs.isNotEmpty) ...[
                          Text(
                            'TECHNOLOGIES USED',
                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: kDarkGrey,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: techs
                                .map((t) => _CardTechChip(label: t))
                                .toList(),
                          ),
                          SizedBox(height: 14.h),
                        ],
                        if (data.sourceUrl.isNotEmpty)
                          GestureDetector(
                            onTap: _launch,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _linkIcon(),
                                  size: 14.sp,
                                  color: kThemeColor,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'Visit Project',
                                  style: TextStyle(
                                    fontFamily: kFontDMSans,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: kThemeColor,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Icon(
                                  Icons.arrow_outward_rounded,
                                  size: 12.sp,
                                  color: kThemeColor,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTechChip extends StatelessWidget {
  const _CardTechChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: kDark,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: kLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Achievement row ────────────────────────────────────────────────────────

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.data});
  final AchievementItem data;

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
        ],
      ),
    );
  }
}

// ── No data placeholder ────────────────────────────────────────────────────

class _NoDataText extends StatelessWidget {
  const _NoDataText();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Text(
          'No data to display',
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

// ── Empty section placeholder ──────────────────────────────────────────────

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
            child: const Text('Retry', style: TextStyle(color: kThemeColor)),
          ),
        ],
      ),
    );
  }
}

// ── Confidential card ──────────────────────────────────────────────────────

class _ConfidentialCard extends StatelessWidget {
  const _ConfidentialCard({
    required this.email,
    required this.phone,
    required this.isReadOnly,
    required this.isPrivateInfoVisible,
    this.onToggleVisibility,
  });

  final String email;
  final String phone;
  final bool isReadOnly;
  final bool isPrivateInfoVisible;
  final ValueChanged<bool>? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    // Determine if data should be masked or shown
    final shouldHideData = isReadOnly && !isPrivateInfoVisible;

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
              // Render Toggle Switch for self, or Lock Icon for external users
              if (!isReadOnly)
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isPrivateInfoVisible,
                    onChanged: onToggleVisibility,
                    activeColor: kTeal,
                    activeTrackColor: Colors.white24,
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white12,
                  ),
                )
              else
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    shouldHideData
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                    color: Colors.white60,
                    size: 18.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),

          // Contact Details Or Privacy Status Mask
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'EMAIL',
            value: shouldHideData
                ? 'Information is private'
                : (email.isEmpty ? 'Not provided' : email),
            isMasked: shouldHideData,
          ),
          SizedBox(height: 14.h),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'PHONE NO.',
            value: shouldHideData
                ? 'Information is private'
                : (phone.isEmpty ? 'Not provided' : phone),
            isMasked: shouldHideData,
          ),

          SizedBox(height: 18.h),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(
                shouldHideData
                    ? Icons.shield_outlined
                    : Icons.verified_user_outlined,
                size: 12.sp,
                color: Colors.white38,
              ),
              SizedBox(width: 6.w),
              Text(
                shouldHideData
                    ? 'PRIVATE ACCESS ONLY'
                    : 'PUBLICLY VISIBLE VIA SETTING',
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
    this.isMasked = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isMasked;

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
                color: isMasked ? Colors.white30 : kLight,
                fontStyle: isMasked ? FontStyle.italic : FontStyle.normal,
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
  const _EducationCard({required this.item});
  final EducationItem item;

  @override
  Widget build(BuildContext context) {
    final hasDegreeOrBranch = item.degree.isNotEmpty || item.branch.isNotEmpty;
    final displayFieldOfStudy = [
      item.degree,
      item.branch,
    ].where((s) => s.isNotEmpty).join(' in ');

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
            value: item.college.isEmpty ? '—' : item.college,
            valueFontSize: 18.sp,
          ),
          if (hasDegreeOrBranch) ...[
            SizedBox(height: 16.h),
            _EduField(
              label: 'FIELD OF STUDY',
              value: displayFieldOfStudy,
              valueFontSize: 14.sp,
            ),
          ],
          if (item.classOf.isNotEmpty || item.cgpa.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                if (item.classOf.isNotEmpty)
                  Expanded(
                    child: _EduField(
                      label: 'GRADUATION',
                      value: 'Class of ${item.classOf}',
                      valueFontSize: 14.sp,
                    ),
                  ),
                if (item.classOf.isNotEmpty && item.cgpa.isNotEmpty)
                  SizedBox(width: 16.w),
                if (item.cgpa.isNotEmpty)
                  Expanded(
                    child: _EduField(
                      label: 'ACADEMIC RANK',
                      value: '${item.cgpa} CGPA',
                      valueFontSize: 14.sp,
                    ),
                  ),
              ],
            ),
          ],
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
  const _LinkRow({required this.item});
  final LinkItem item;

  IconData _icon() {
    final u = item.url.toLowerCase();
    if (u.contains('linkedin')) return Icons.work_outline;
    if (u.contains('github')) return Icons.code_rounded;
    if (u.contains('twitter') || u.contains('x.com'))
      return Icons.alternate_email;
    if (u.contains('instagram')) return Icons.camera_alt_outlined;
    if (u.contains('youtube')) return Icons.play_circle_outline;
    if (u.contains('behance')) return Icons.brush_outlined;
    if (u.contains('dribbble')) return Icons.sports_basketball_outlined;
    if (u.contains('medium')) return Icons.article_outlined;
    if (u.contains('figma')) return Icons.design_services_outlined;
    if (u.contains('notion')) return Icons.sticky_note_2_outlined;
    return Icons.language_outlined;
  }

  Future<void> _launch() async {
    if (item.url.isEmpty) return;
    final uri = Uri.tryParse(item.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback if label is empty but url is present
    final displayLabel = item.label.isEmpty ? item.url : item.label;

    return GestureDetector(
      onTap: _launch,
      child: Container(
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
            Icon(_icon(), size: 18.sp, color: kDark),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.open_in_new, size: 14.sp, color: kDarkGrey),
          ],
        ),
      ),
    );
  }
}
