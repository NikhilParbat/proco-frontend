import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/helpers/chat_helper.dart';
import 'package:proco/views/ui/chat/chat_page.dart';
import 'package:proco/views/ui/jobs/match_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_detail_page.dart';

/// Full-screen single-card swipe view opened when the user taps a parallax card.
///
/// Swipe RIGHT → matched → MatchDialog (Go to Chat | Back to list)
/// Swipe LEFT  → not interested → Navigator.pop() back to parallax screen
/// "View Profile" button → UserDetailPage
class UserSwipePage extends StatefulWidget {
  final SwipedRes user;
  final String jobId;

  const UserSwipePage({
    super.key,
    required this.user,
    required this.jobId,
  });

  @override
  State<UserSwipePage> createState() => _UserSwipePageState();
}

class _UserSwipePageState extends State<UserSwipePage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _accept = Color(0xFF2DB67D);
  static const Color _reject = Color(0xFFE8505B);
  static const Color _bg = Color(0xFFF7F7F7);

  late final CardSwiperController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Match action ─────────────────────────────────────────────────────────

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
            // Close dialog then navigate to chat (leaves the parallax stack)
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
          onBackToList: () {
            // Close dialog then pop swipe page → lands on parallax screen
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.user.username,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: _navy,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),

            // Hint row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hintChip(Icons.close_rounded, 'Skip', _reject),
                  _hintChip(Icons.favorite_rounded, 'Match', _accept),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Single swipeable card
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: CardSwiper(
                  controller: _controller,
                  cardsCount: 1,
                  numberOfCardsDisplayed: 1,
                  padding: EdgeInsets.only(bottom: 16.h),
                  allowedSwipeDirection: const AllowedSwipeDirection.only(
                    left: true,
                    right: true,
                  ),
                  onSwipe: (prevIndex, currentIndex, direction) async {
                    if (direction == CardSwiperDirection.right) {
                      await _onMatch();
                    } else {
                      // Left swipe → not interested → back to parallax
                      Navigator.of(context).pop();
                    }
                    return true;
                  },
                  isLoop: false,
                  cardBuilder: (context, index, pctX, pctY) {
                    CardSwiperDirection? liveDir;
                    const threshold = 0.12;
                    if (pctX > threshold) liveDir = CardSwiperDirection.right;
                    if (pctX < -threshold) liveDir = CardSwiperDirection.left;
                    return _SwipeCard(
                      user: widget.user,
                      liveDirection: liveDir,
                      onViewProfile: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailPage(
                            user: widget.user,
                            jobId: widget.jobId,
                            onMatch: _onMatch,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // FAB hint — tap heart to trigger right swipe
            Padding(
              padding: EdgeInsets.only(bottom: 24.h, top: 4.h),
              child: GestureDetector(
                onTap: () => _controller.swipe(CardSwiperDirection.right),
                child: Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: _accept,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accept.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 26.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hintChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
}

// ─── Private card widget ───────────────────────────────────────────────────

class _SwipeCard extends StatelessWidget {
  final SwipedRes user;
  final CardSwiperDirection? liveDirection;
  final VoidCallback onViewProfile;

  static const Color _teal = Color(0xFF08979F);
  static const Color _navy = Color(0xFF040326);
  static const Color _accept = Color(0xFF2DB67D);
  static const Color _reject = Color(0xFFE8505B);
  static const Color _orange = Color(0xFFf55631);

  const _SwipeCard({
    required this.user,
    required this.onViewProfile,
    this.liveDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = liveDirection == CardSwiperDirection.right;
    final isLeft = liveDirection == CardSwiperDirection.left;
    final hasOverlay = liveDirection != null;

    return Container(
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Photo — top 60%
              Expanded(
                flex: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      user.profile,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _teal.withValues(alpha: 0.08),
                        child: const Icon(Icons.person_rounded,
                            color: _teal, size: 64),
                      ),
                    ),
                    // Gradient fade into dark base
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _navy.withValues(alpha: 0.55),
                              _navy,
                            ],
                            stops: const [0.5, 0.82, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info — bottom 40%
              Expanded(
                flex: 40,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Location
                      if (user.location.isNotEmpty) ...[
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: _orange, size: 13),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                user.location,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white60,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 10.h),

                      // View Profile button
                      GestureDetector(
                        onTap: onViewProfile,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _teal.withValues(alpha: 0.40)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_rounded,
                                  color: _teal, size: 13),
                              SizedBox(width: 5.w),
                              Text(
                                'View Profile',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: _teal,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Skills
                      if (user.skills.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: user.skills.take(5).map((skill) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: _teal.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _teal.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  skill,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: _teal,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Swipe direction overlay
          if (hasOverlay)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      (isRight ? _accept : _reject).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: isRight ? _accept : _reject,
                    width: 2.5,
                  ),
                ),
                child: Align(
                  alignment:
                      isRight ? Alignment.topRight : Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 28.h,
                      left: isLeft ? 20.w : 0,
                      right: isRight ? 20.w : 0,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isRight ? _accept : _reject,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRight
                                ? Icons.favorite_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            isRight ? 'MATCH' : 'SKIP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
