import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/services/helpers/chat_helper.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:proco/views/ui/chat/chat_page.dart';
import 'package:proco/views/ui/jobs/match_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proco/views/ui/profile/profile_screen.dart';

class ApplicantDetailPage extends StatefulWidget {
  final SwipedRes user;
  final String jobId;
  final int totalApplicants;

  const ApplicantDetailPage({
    super.key,
    required this.user,
    required this.jobId,
    required this.totalApplicants,
  });

  @override
  State<ApplicantDetailPage> createState() => _ApplicantDetailPageState();
}

class _ApplicantDetailPageState extends State<ApplicantDetailPage>
    with SingleTickerProviderStateMixin {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _reject = Color(0xFFE8505B);
  static const Color _bg = Color(0xFFF7F7F7);

  // Parallax scroll tracking
  late final ScrollController _scrollController;

  // Swipe-right animation played when the match (heart) button is tapped
  late final AnimationController _swipeCtrl;
  late final Animation<Offset> _swipeAnim;

  bool _isLoadingProfile = true;
  UserResponse? _profile;

  static const double _headerHeight = 320;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _swipeAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.6, 0),
    ).animate(CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeInBack));

    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _swipeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final res = await UserHelper.fetchUserById(widget.user.id);
    if (!mounted) return;
    setState(() {
      _profile = res.data;
      _isLoadingProfile = false;
    });
  }

  int? _calcAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    try {
      final date = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  // ── Match action (unchanged logic) ────────────────────────────────────────

  Future<void> _onMatch() async {
    Provider.of<JobsNotifier>(context, listen: false)
        .addMatchedUsers(widget.jobId, widget.user.id);

    final response =
        await ChatHelper.createChat(CreateChat(userId: widget.user.id));
    if (!mounted) return;

    if (response.success && response.data != null) {
      final chatId = response.data!;
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId') ?? '';
      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (dialogContext) => MatchDialog(
          user: widget.user,
          onGoToChat: () {
            Navigator.of(dialogContext).pop();
            Get.to(() => ChatPage(
                  id: chatId,
                  title: widget.user.username,
                  profile: widget.user.profile,
                  user: [currentUserId, widget.user.id],
                ));
          },
          onBackToList: () {
            // Close dialog → pop this page → lands back on parallax screen
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    } else {
      // On error, reverse the swipe animation so the card snaps back
      if (mounted) _swipeCtrl.reverse();
      Get.snackbar(
        'Error',
        response.message,
        backgroundColor: _reject,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // Plays swipe-right animation then triggers the match logic
  Future<void> _handleMatch() async {
    _swipeCtrl.reset();
    await _swipeCtrl.forward();
    await _onMatch();
    // Reset so the card is visible again if the user returns via chat back-nav
    if (mounted) _swipeCtrl.reset();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final u = _profile;
    final age = _calcAge(u?.dob);
    final college = u?.college ?? '';
    final branch = u?.branch ?? '';
    final skills =
        (u?.skills.isNotEmpty == true) ? u!.skills : widget.user.skills;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Parallax scroll (slides right on match) ──────────────────────
          SlideTransition(
            position: _swipeAnim,
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, _) {
                final scrollOffset = _scrollController.hasClients
                    ? _scrollController.offset
                    : 0.0;
                final parallaxFraction =
                    (scrollOffset / _headerHeight).clamp(0.0, 1.0);
                final imageAlignment =
                    Alignment(0, -parallaxFraction * 0.6);

                // Gaussian depth shadow — mirrors ParallaxUserCard
                final gauss = math.exp(
                  -(math.pow((parallaxFraction - 0.5), 2) / 0.08),
                );
                final headerElevation = gauss * 8.0;

                return CustomScrollView(
                  controller: _scrollController,
                  // Extra bottom padding so content isn't hidden behind action bar
                  slivers: [
                    SliverAppBar(
                      expandedHeight: _headerHeight.h,
                      pinned: true,
                      backgroundColor: _bg,
                      elevation: headerElevation,
                      shadowColor: Colors.black26,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _navy,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: AnimatedOpacity(
                        opacity: parallaxFraction > 0.6 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          widget.user.username,
                          style: TextStyle(
                            fontFamily: kFontDMSans,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.none,
                        background: _buildParallaxImage(imageAlignment),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28.r),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              20.w, 24.h, 20.w, 120.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + applicants count
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.user.username,
                                      style: TextStyle(
                                        fontFamily: kFontDMSans,
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _navy,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      color: _teal.withValues(alpha: 0.10),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${widget.totalApplicants} applicant${widget.totalApplicants == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontFamily: kFontDMSans,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: _teal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Location
                              if (widget.user.location.isNotEmpty) ...[
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: kOrange, size: 14),
                                    SizedBox(width: 4.w),
                                    Text(
                                      widget.user.location,
                                      style: TextStyle(
                                        fontFamily: kFontDMSans,
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              SizedBox(height: 20.h),

                              // Bio
                              if (_isLoadingProfile)
                                _bioShimmer()
                              else if (college.isNotEmpty ||
                                  age != null) ...[
                                _sectionLabel('BIO'),
                                SizedBox(height: 10.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(14.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (college.isNotEmpty)
                                        _bioRow(
                                            Icons.school_rounded, college),
                                      if (branch.isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        _bioRow(Icons.account_tree_rounded,
                                            branch),
                                      ],
                                      if (age != null) ...[
                                        SizedBox(height: 8.h),
                                        _bioRow(Icons.cake_rounded,
                                            '$age years old'),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                              ],

                              // Skills
                              if (skills.isNotEmpty) ...[
                                _sectionLabel('SKILLS'),
                                SizedBox(height: 10.h),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills
                                      .take(6)
                                      .map(_skillChip)
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Action bar: ❌  |  View Profile  |  ❤️ ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildActionBar(context),
          ),
        ],
      ),
    );
  }

  // ── Parallax header image ──────────────────────────────────────────────────

  Widget _buildParallaxImage(Alignment alignment) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.user.profile.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.user.profile,
                fit: BoxFit.cover,
                // Focal point shifts with scroll — same as ParallaxUserCard
                alignment: alignment,
                placeholder: (_, __) =>
                    Container(color: _teal.withValues(alpha: 0.06)),
                errorWidget: (_, __, ___) => _profilePlaceholder(),
              )
            : _profilePlaceholder(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _navy.withValues(alpha: 0.55),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14.h,
          right: 14.w,
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'ACTIVE NOW',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: _navy,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Action bar ─────────────────────────────────────────────────────────────

  Widget _buildActionBar(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final btnSize = 64.w;
    final smallSize = 54.w;

    Widget circleBtn({
      required Widget icon,
      required VoidCallback onTap,
      required double size,
      Color bg = Colors.white,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.45),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h + bottomPad),
      decoration: BoxDecoration(
        color: _bg,
        border:
            Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ❌ Not interested — directly back to parallax screen
          circleBtn(
            size: smallSize,
            icon: Icon(CupertinoIcons.xmark,
                color: Colors.black87, size: 26.sp),
            onTap: () => Navigator.pop(context),
          ),

          // View Profile — centre
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(
                  viewUserId: widget.user.id,
                ),
              ),
            ),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded,
                      color: Colors.white, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'View Profile',
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

          // ❤️ Match — swipe-right animation → MatchDialog
          circleBtn(
            size: btnSize,
            icon: PhosphorIcon(
              PhosphorIcons.heartStraight(),
              color: const Color(0xFFE6B8A2),
              size: 30.sp,
            ),
            onTap: _handleMatch,
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _profilePlaceholder() => Container(
        color: _teal.withValues(alpha: 0.08),
        child: Center(
          child: Icon(Icons.person_rounded, color: _teal, size: 72.r),
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      );

  Widget _bioRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: _teal, size: 16),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: _navy,
              ),
            ),
          ),
        ],
      );

  Widget _skillChip(String skill) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
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

  Widget _bioShimmer() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BIO'),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF08979F), strokeWidth: 2),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      );
}
