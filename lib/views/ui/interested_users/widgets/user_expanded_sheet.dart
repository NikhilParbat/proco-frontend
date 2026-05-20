import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/user/user_response.dart';

import 'package:proco/services/helpers/chat_helper.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:proco/views/ui/chat/chat_page.dart';
import 'package:proco/views/ui/jobs/match_dialog.dart';
import 'package:proco/views/ui/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UserExpandedSheet extends StatefulWidget {
  final SwipedRes user;
  final String jobId;
  final int totalApplicants;

  const UserExpandedSheet({
    super.key,
    required this.user,
    required this.jobId,
    required this.totalApplicants,
  });

  @override
  State<UserExpandedSheet> createState() => _UserExpandedSheetState();
}

class _UserExpandedSheetState extends State<UserExpandedSheet> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _orange = Color(0xFFf55631);

  bool _isLoading = true;
  bool _isMatching = false;
  UserResponse? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final res = await UserHelper.fetchUserById(widget.user.id);
    if (!mounted) return;
    setState(() {
      _profile = res.data;
      _isLoading = false;
    });
  }

  Future<void> _onMatch() async {
    setState(() => _isMatching = true);

    Provider.of<JobsNotifier>(context, listen: false)
        .addMatchedUsers(widget.jobId, widget.user.id);

    final response = await ChatHelper.createChat(
      CreateChat(userId: widget.user.id),
    );
    if (!mounted) return;

    setState(() => _isMatching = false);

    if (response.success && response.data != null) {
      final chatId = response.data!;
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId') ?? '';
      if (!mounted) return;

      Navigator.of(context).pop();

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (dialogContext) => MatchDialog(
          user: widget.user,
          onGoToChat: () {
            Navigator.of(dialogContext).pop();
            Get.to(
              () => ChatPage(
                id: chatId,
                title: widget.user.username,
                profile: widget.user.profile,
                user: [currentUserId, widget.user.id],
              ),
            );
          },
          onBackToList: () => Navigator.of(dialogContext).pop(),
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        response.message,
        backgroundColor: const Color(0xFFE8505B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  int _calculateAge(String dobString) {
    if (dobString.isEmpty) return 0;
    try {
      final dob = DateTime.parse(dobString);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
         
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer full profile data; fall back to the minimal SwipedRes passed in.
    final bio = _profile?.bio ?? widget.user.bio;
    final skills = (_profile != null && _profile!.skills.isNotEmpty)
        ? _profile!.skills
        : widget.user.skills;

    final rawCity = _profile?.city ?? widget.user.city;
    final rawCountry = _profile?.country ?? widget.user.country;
    final location = (rawCity.isNotEmpty && rawCountry.isNotEmpty)
        ? '$rawCity, $rawCountry'
        : (rawCity.isNotEmpty ? rawCity : rawCountry);

    final rawDob = _profile?.dob ?? widget.user.dob;
    final rawGender = _profile?.gender ?? widget.user.gender;
    final age = _calculateAge(rawDob ?? '');
    final genderStr = (rawGender?.isNotEmpty == true)
        ? '${rawGender![0].toUpperCase()}${rawGender.substring(1)}'
        : '';
    final quickFacts = [
      if (age > 0) '$age yrs',
      if (genderStr.isNotEmpty) genderStr,
    ].join(' • ');

    // Education — prefer full profile, sort newest first.
    final eduSource = (_profile != null && _profile!.education.isNotEmpty)
        ? _profile!.education
        : widget.user.education;
    final sortedEducation = List<EducationItem>.from(eduSource);
    sortedEducation.sort((a, b) {
      final yearA = int.tryParse(a.classOf) ?? 0;
      final yearB = int.tryParse(b.classOf) ?? 0;
      return yearB.compareTo(yearA);
    });

    final experiences = _profile?.experiences ?? [];
    final projects = _profile?.projects ?? [];
    final achievements = _profile?.achievements ?? [];
    final interests = _profile?.interests ?? [];
    final hobbies = _profile?.hobbies ?? [];
    final links = (_profile != null && _profile!.links.isNotEmpty)
        ? _profile!.links
        : widget.user.links;

    // Social URLs
    final linkedIn = _profile?.linkedInUrl ?? '';
    final github = _profile?.gitHubUrl ?? '';
    final twitter = _profile?.twitterUrl ?? '';
    final portfolio = _profile?.portfolioUrl ?? '';
    final hasSocials =
        linkedIn.isNotEmpty || github.isNotEmpty || twitter.isNotEmpty || portfolio.isNotEmpty;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero photo ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: screenHeight * 0.60,
            pinned: true,
            stretch: true,
            backgroundColor: _navy,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.all(8.w),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _navy,
                    size: 16,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  widget.user.profile.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.user.profile,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(
                            color: _teal.withValues(alpha: 0.10),
                          ),
                          errorWidget: (ctx, url, err) => _placeholder(),
                        )
                      : _placeholder(),

                  // Top gradient — keeps back button readable
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient + name overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.80),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.65],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 22.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.user.username,
                              style: TextStyle(
                                fontFamily: kFontDMSans,
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            if (quickFacts.isNotEmpty) ...[
                              SizedBox(height: 5.h),
                              Text(
                                quickFacts,
                                style: TextStyle(
                                  fontFamily: kFontDMSans,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  if (location.isNotEmpty)
                    _infoRow(
                      icon: Icons.location_on_rounded,
                      iconColor: _orange,
                      text: location,
                    ),

                  // Bio
                  if (_isLoading) ...[
                    SizedBox(height: 16.h),
                    _shimmerLine(width: 0.85),
                    SizedBox(height: 6.h),
                    _shimmerLine(width: 0.65),
                  ] else if (bio.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      bio,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Education
                  if (sortedEducation.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('EDUCATION'),
                    SizedBox(height: 8.h),
                    ...sortedEducation.map(_educationRow),
                  ],

                  // Experience
                  if (experiences.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('EXPERIENCE'),
                    SizedBox(height: 8.h),
                    ...experiences.map(_experienceRow),
                  ],

                  // Projects
                  if (projects.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('PROJECTS'),
                    SizedBox(height: 8.h),
                    ...projects.map(_projectRow),
                  ],

                  // Achievements
                  if (achievements.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('ACHIEVEMENTS'),
                    SizedBox(height: 8.h),
                    ...achievements.map(_achievementRow),
                  ],

                  // Skills
                  if (skills.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('SKILLS'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map(_skillChip).toList(),
                    ),
                  ],

                  // Interests & Hobbies
                  if (interests.isNotEmpty || hobbies.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('INTERESTS & HOBBIES'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...interests.map((s) => _tagChip(s, _teal)),
                        ...hobbies.map((s) => _tagChip(s, _navy)),
                      ],
                    ),
                  ],

                  // Links (from profile)
                  if (links.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('LINKS & PORTFOLIOS'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 6.h,
                      children: links.map(_linkChip).toList(),
                    ),
                  ],

                  // Social profiles
                  if (hasSocials) ...[
                    SizedBox(height: 24.h),
                    _sectionLabel('SOCIAL PROFILES'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: [
                        if (linkedIn.isNotEmpty)
                          _socialButton(
                              label: 'LinkedIn',
                              icon: Icons.work_history_rounded,
                              url: linkedIn),
                        if (github.isNotEmpty)
                          _socialButton(
                              label: 'GitHub',
                              icon: Icons.code_rounded,
                              url: github),
                        if (twitter.isNotEmpty)
                          _socialButton(
                              label: 'Twitter',
                              icon: Icons.alternate_email_rounded,
                              url: twitter),
                        if (portfolio.isNotEmpty)
                          _socialButton(
                              label: 'Portfolio',
                              icon: Icons.open_in_new_rounded,
                              url: portfolio),
                      ],
                    ),
                  ],

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(viewUserId: widget.user.id),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _navy.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_rounded, color: _navy, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Visit Profile',
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GestureDetector(
              onTap: _isMatching ? null : _onMatch,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isMatching
                    ? const SizedBox(
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Match',
                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationRow(EducationItem edu) {
    final degreeAndBranch = [
      if (edu.degree.isNotEmpty) edu.degree,
      if (edu.branch.isNotEmpty) edu.branch,
    ].join(' in ');

    final collegeAndYear = [
      if (edu.college.isNotEmpty) edu.college,
      if (edu.classOf.isNotEmpty) '(${edu.classOf})',
    ].join(' ');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_rounded, color: _teal, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (degreeAndBranch.isNotEmpty)
                  Text(
                    degreeAndBranch,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                if (collegeAndYear.isNotEmpty)
                  Text(
                    collegeAndYear,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (edu.cgpa.isNotEmpty)
                  Text(
                    'CGPA: ${edu.cgpa}',
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 11.sp,
                      color: _teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkChip(LinkItem link) {
    IconData linkIcon = Icons.link_rounded;
    if (link.label.toLowerCase().contains('github')) {
      linkIcon = Icons.code_rounded;
    } else if (link.label.toLowerCase().contains('linkedin')) {
      linkIcon = Icons.work_history_rounded;
    }

    return InkWell(
      onTap: () async {
        if (link.url.isNotEmpty) {
          final uri = Uri.parse(link.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Chip(
        avatar: Icon(linkIcon, size: 14.sp, color: _teal),
        label: Text(
          link.label,
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: _navy,
          ),
        ),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      );

  Widget _placeholder() => Container(
        color: _teal.withValues(alpha: 0.08),
        child: Center(
          child: Icon(Icons.person_rounded, color: _teal, size: 80),
        ),
      );

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) =>
      Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      );

  Widget _skillChip(String skill) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          skill.toUpperCase(),
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _experienceRow(ExperienceItem exp) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.work_outline_rounded, color: _orange, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.position,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  Text(
                    exp.company,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (exp.dateRange.isNotEmpty)
                    Text(
                      exp.dateRange,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 11.sp,
                        color: _teal,
                      ),
                    ),
                  if (exp.description.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        exp.description,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _projectRow(ProjectItem proj) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.code_rounded, color: _teal, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proj.name,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  if (proj.domain.isNotEmpty)
                    Text(
                      proj.domain,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 12.sp,
                        color: _teal,
                      ),
                    ),
                  if (proj.description.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        proj.description,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (proj.technologies.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: proj.technologies
                            .map((t) => _tagChip(t, _navy))
                            .toList(),
                      ),
                    ),
                  if (proj.sourceUrl.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(proj.sourceUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 12.sp, color: _teal),
                            SizedBox(width: 4.w),
                            Text(
                              'View source',
                              style: TextStyle(
                                fontFamily: kFontDMSans,
                                fontSize: 12.sp,
                                color: _teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _achievementRow(AchievementItem ach) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.emoji_events_rounded,
                  color: Colors.amber.shade700, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ach.title,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  if (ach.subtitle.isNotEmpty)
                    Text(
                      ach.subtitle,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tagChip(String label, Color color) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 11.sp,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _socialButton({
    required String label,
    required IconData icon,
    required String url,
  }) =>
      InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _navy.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.sp, color: _navy),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _shimmerLine({required double width}) => Container(
        height: 14.h,
        width: MediaQuery.of(context).size.width * width,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}
