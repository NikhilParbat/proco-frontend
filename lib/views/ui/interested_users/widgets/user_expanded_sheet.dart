import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
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

    Provider.of<JobsNotifier>(
      context,
      listen: false,
    ).addMatchedUsers(widget.jobId, widget.user.id);

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

  @override
  Widget build(BuildContext context) {
    final bio = _profile?.bio ?? '';
    final college = _profile?.education[0] ?? '';
    final skills = (_profile?.skills.isNotEmpty == true)
        ? _profile!.skills
        : widget.user.skills;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Profile image ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: SizedBox(
                      height: 230.h,
                      width: double.infinity,
                      child: widget.user.profile.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.user.profile,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: _teal.withValues(alpha: 0.08),
                              ),
                              errorWidget: (context, url, err) =>
                                  _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  // ACTIVE NOW badge
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
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
              ),
            ),

            // ── User info ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.user.username,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                      height: 1.1,
                    ),
                  ),

                  // Bio
                  if (_isLoading) ...[
                    SizedBox(height: 8.h),
                    _shimmerLine(width: 0.7),
                    SizedBox(height: 6.h),
                    _shimmerLine(width: 0.5),
                  ] else if (bio.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],

                  SizedBox(height: 12.h),

                  // Location
                  if (widget.user.location.isNotEmpty)
                    _infoRow(
                      icon: Icons.location_on_rounded,
                      iconColor: _orange,
                      text: widget.user.location,
                    ),

                  // College
                  if (!_isLoading) ...[
                    SizedBox(height: 6.h),
                    _infoRow(
                      icon: Icons.school_rounded,
                      iconColor: _teal,
                      text: college.toString(),
                    ),
                  ],

                  // TOP SKILLS
                  if (skills.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      'TOP SKILLS',
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills.take(4).map(_skillChip).toList(),
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // ── Action buttons ─────────────────────────────────────
                  Row(
                    children: [
                      // Visit Profile
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfilePage(viewUserId: widget.user.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _navy.withValues(alpha: 0.8),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: _navy,
                                  size: 16.sp,
                                ),
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

                      // Match
                      Expanded(
                        child: GestureDetector(
                          onTap: _isMatching ? null : _onMatch,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 13.h),
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

                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 20.h,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: _teal.withValues(alpha: 0.08),
    child: Center(child: Icon(Icons.person_rounded, color: _teal, size: 64)),
  );

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) => Row(
    children: [
      Icon(icon, color: iconColor, size: 14),
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

  Widget _shimmerLine({required double width}) => Container(
    height: 12.h,
    width: MediaQuery.of(context).size.width * width,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
