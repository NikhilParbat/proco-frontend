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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_detail_page.dart';

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

class _ApplicantDetailPageState extends State<ApplicantDetailPage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _reject = Color(0xFFE8505B);
  static const Color _bg = Color(0xFFF7F7F7);

  bool _isLoadingProfile = true;
  UserResponse? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    } else {
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

  @override
  Widget build(BuildContext context) {
    final u = _profile;
    final age = _calcAge(u?.dob);
    final gender = u?.gender ?? '';
    final college = u?.college ?? '';
    final branch = u?.branch ?? '';
    final skills =
        (u?.skills.isNotEmpty == true) ? u!.skills : widget.user.skills;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicants',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            Text(
              '${widget.totalApplicants} Applicant${widget.totalApplicants == 1 ? '' : 's'}',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              _buildInfoSection(
                u: u,
                age: age,
                gender: gender,
                college: college,
                branch: branch,
                skills: skills,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: Stack(
        children: [
          SizedBox(
            height: 270.h,
            width: double.infinity,
            child: widget.user.profile.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.user.profile,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: _teal.withValues(alpha: 0.06)),
                    errorWidget: (_, _, _) => _profilePlaceholder(),
                  )
                : _profilePlaceholder(),
          ),
          Positioned(
            bottom: 12.h,
            right: 12.w,
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
      ),
    );
  }

  Widget _profilePlaceholder() => Container(
        color: _teal.withValues(alpha: 0.08),
        child: Center(
          child: Icon(Icons.person_rounded, color: _teal, size: 72.r),
        ),
      );

  Widget _buildInfoSection({
    required UserResponse? u,
    required int? age,
    required String gender,
    required String college,
    required String branch,
    required List<String> skills,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
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

          SizedBox(height: 16.h),

          // Location
          if (widget.user.location.isNotEmpty)
            _infoRow(Icons.location_on_rounded, kOrange,
                widget.user.location),

          // Gender
          if (gender.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _infoRow(Icons.location_on_rounded, kOrange, gender),
          ],

          // Age
          if (age != null) ...[
            SizedBox(height: 10.h),
            _infoRow(Icons.location_on_rounded, kOrange, '$age'),
          ],

          SizedBox(height: 22.h),

          // TOP SKILLS
          if (skills.isNotEmpty) ...[
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
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .take(6)
                  .map((skill) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 7.h),
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
                      ))
                  .toList(),
            ),
            SizedBox(height: 22.h),
          ],

          // EDUCATION
          if (_isLoadingProfile)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                    color: Color(0xFF08979F), strokeWidth: 2),
              ),
            )
          else if (college.isNotEmpty) ...[
            Text(
              'EDUCATION',
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                const Icon(Icons.school_rounded, color: _teal, size: 16),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    college,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
            if (branch.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  const Icon(Icons.account_tree_rounded,
                      color: _teal, size: 16),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      branch,
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24.h),
          ] else
            SizedBox(height: 4.h),

          // View Profile button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailPage(
                    user: widget.user,
                    jobId: widget.jobId,
                    onMatch: _onMatch,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'View Profile',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String text) => Row(
        children: [
          Icon(icon, color: iconColor, size: 15),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      );
}
