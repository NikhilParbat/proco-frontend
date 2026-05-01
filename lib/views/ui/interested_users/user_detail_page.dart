import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/services/helpers/user_helper.dart';

/// Full profile view for an interested user.
/// The caller owns the match logic and passes it in via [onMatch].
class UserDetailPage extends StatefulWidget {
  final SwipedRes user;
  final String jobId;
  final Future<void> Function() onMatch;

  const UserDetailPage({
    super.key,
    required this.user,
    required this.jobId,
    required this.onMatch,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _orange = Color(0xFFf55631);
  static const Color _accept = Color(0xFF2DB67D);

  bool _isMatching = false;
  bool _isLoadingProfile = true;
  ApiResponse<UserResponse>? _fullProfile;

  @override
  void initState() {
    super.initState();
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    final profile = await UserHelper.fetchUserById(widget.user.id);
    if (!mounted) return;
    setState(() {
      _fullProfile = profile;
      _isLoadingProfile = false;
    });
  }

  Future<void> _handleMatch() async {
    setState(() => _isMatching = true);
    await widget.onMatch();
    if (mounted) setState(() => _isMatching = false);
  }

  bool get _hasAnySocialLink {
    final u = _fullProfile?.data;
    if (u == null) return false;
    return (u.linkedInUrl ?? '').isNotEmpty ||
        (u.gitHubUrl ?? '').isNotEmpty ||
        (u.twitterUrl ?? '').isNotEmpty ||
        (u.portfolioUrl ?? '').isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final u = _fullProfile?.data;
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.user.username,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
          child: GestureDetector(
            onTap: _isMatching ? null : _handleMatch,
            child: Container(
              height: 54.h,
              decoration: BoxDecoration(
                color: _accept,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _accept.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isMatching
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Match',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile photo ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  widget.user.profile,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _teal.withValues(alpha: 0.10),
                    child:
                        const Icon(Icons.person_rounded, color: _teal, size: 80),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // ── Name ──────────────────────────────────────────────────────
            Text(
              widget.user.username,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),

            // ── Location ──────────────────────────────────────────────────
            if (widget.user.location.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _orange, size: 15),
                  SizedBox(width: 4.w),
                  Text(
                    widget.user.location,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white60,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],

            // ── Skills ────────────────────────────────────────────────────
            if (widget.user.skills.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _sectionLabel('SKILLS'),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.user.skills
                    .map(
                      (skill) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _teal.withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _teal,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // ── Full profile (from backend) ────────────────────────────────
            if (_isLoadingProfile)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: _teal, strokeWidth: 2),
                ),
              )
            else if (u != null) ...[
              // Education
              if ((u.college ?? '').isNotEmpty) ...[
                SizedBox(height: 24.h),
                _sectionLabel('EDUCATION'),
                SizedBox(height: 10.h),
                _infoRow(Icons.school_rounded, u.college!),
                if ((u.branch ?? '').isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _infoRow(Icons.account_tree_rounded, u.branch!),
                ],
              ],

              // Social links
              if (_hasAnySocialLink) ...[
                SizedBox(height: 24.h),
                _sectionLabel('LINKS'),
                SizedBox(height: 10.h),
                if ((u.linkedInUrl ?? '').isNotEmpty)
                  _linkRow('LinkedIn', u.linkedInUrl),
                if ((u.gitHubUrl ?? '').isNotEmpty)
                  _linkRow('GitHub', u.gitHubUrl),
                if ((u.twitterUrl ?? '').isNotEmpty)
                  _linkRow('Twitter', u.twitterUrl),
                if ((u.portfolioUrl ?? '').isNotEmpty)
                  _linkRow('Portfolio', u.portfolioUrl),
              ],
            ],

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.white38,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: 1.2,
        ),
      );

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: _teal, size: 16),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      );

  Widget _linkRow(String label, String? url) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, color: _teal, size: 16),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '$label: $url',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
