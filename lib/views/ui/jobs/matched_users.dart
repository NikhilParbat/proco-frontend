import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/helpers/chat_helper.dart';
import 'package:proco/views/ui/chat/chat_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MatchedUsers — horizontal peek carousel (Hinge Standouts style)
// ═══════════════════════════════════════════════════════════════════════════
class MatchedUsers extends StatefulWidget {
  const MatchedUsers({super.key});

  @override
  State<MatchedUsers> createState() => _MatchedUsersState();
}

class _MatchedUsersState extends State<MatchedUsers> {
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);

  String _jobId = '';
  List<SwipedRes> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _jobId = prefs.getString('currentJobId') ?? '';
    if (!mounted) return;
    final notifier = Provider.of<JobsNotifier>(context, listen: false);
    notifier.getSwipedUsersId(_jobId);
    final users = await notifier.swipedUsers;
    if (!mounted) return;
    setState(() {
      _users = users ?? [];
      _loading = false;
    });
  }

  void _removeUser(String userId) {
    setState(() => _users.removeWhere((u) => u.id == userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? _buildLoader()
                  : _users.isEmpty
                  ? _buildEmpty()
                  : _buildCarousel(_users, _jobId),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 10.h, 20.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _navy,
              size: 20,
            ),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interested Users',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Tap a card to swipe · right to match',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Horizontal snap carousel ────────────────────────────────────────────
  Widget _buildCarousel(List<SwipedRes> users, String jobId) {
    final pageController = PageController(viewportFraction: 0.88);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.only(left: 20.w),
          child: Text(
            '${users.length} interested',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: _CarouselCard(
                  user: users[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ProfilePage(
                        user: users[index],
                        jobId: jobId,
                        onMatched: () => _removeUser(users[index].id),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
  );

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60,
            color: _teal.withOpacity(0.25),
          ),
          SizedBox(height: 16.h),
          Text(
            'No interested users yet.\nCheck back soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.grey,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Carousel Card — Hinge Standouts style
// ═══════════════════════════════════════════════════════════════════════════
class _CarouselCard extends StatelessWidget {
  final SwipedRes user;
  final VoidCallback onTap;

  static const Color _teal = Color(0xFF08979F);

  const _CarouselCard({required this.user, required this.onTap});

  String get _promptLabel => user.skills.isNotEmpty ? 'Top skills' : 'Based in';
  String get _promptContent {
    if (user.skills.isNotEmpty) return user.skills.take(3).join(' · ');
    return user.location.isNotEmpty ? user.location : 'No info yet';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          color: const Color(0xFF040326), // always dark navy base
          child: Stack(
            children: [
              // ── Full background photo ──────────────────────────────────
              if (user.profile.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    user.profile,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderBg(),
                  ),
                ),

              // ── Top-left: name + badge ───────────────────────────────────
              Positioned(
                top: 16.h,
                left: 16.w,
                right: 16.w,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom: white prompt box ─────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.r),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 60.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _promptLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _promptContent,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Heart button (bottom-right) ──────────────────────────────
              Positioned(
                right: 14.w,
                bottom: 14.h,
                child: Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.favorite_rounded, color: _teal, size: 22.w),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderBg() => Container(
    color: _teal.withOpacity(0.1),
    child: const Center(
      child: Icon(Icons.person_rounded, color: _teal, size: 80),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Swipe Detail Page — full card swiper after tapping a carousel card
// ═══════════════════════════════════════════════════════════════════════════
class _SwipeDetailPage extends StatefulWidget {
  final List<SwipedRes> users;
  final int initialIndex;
  final String jobId;

  const _SwipeDetailPage({
    required this.users,
    required this.initialIndex,
    required this.jobId,
  });

  @override
  State<_SwipeDetailPage> createState() => _SwipeDetailPageState();
}

class _SwipeDetailPageState extends State<_SwipeDetailPage> {
  late final CardSwiperController _controller;

  static const Color _navy = Color(0xFFF7F7F7);
  static const Color _reject = Color(0xFFE8505B);
  static const Color _accept = Color(0xFF2DB67D);
  static const Color _dark = Color(0xFF040326);

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

  Future<void> _onMatch(SwipedRes user) async {
    Provider.of<JobsNotifier>(
      context,
      listen: false,
    ).addMatchedUsers(widget.jobId, user.id);

    Get.snackbar(
      "It's a Match!",
      "You matched with ${user.username}",
      backgroundColor: _accept,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.favorite, color: Colors.white),
      duration: const Duration(seconds: 3),
    );

    final result = await ChatHelper.createChat(CreateChat(userId: user.id));
    if (!mounted) return;

    if (result['success'] == true) {
      final chatId = result['chatId'] as String;
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId') ?? '';
      Get.to(
        () => ChatPage(
          id: chatId,
          title: user.username,
          profile: user.profile,
          user: [currentUserId, user.id],
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to create chat',
        backgroundColor: _reject,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _viewProfile(SwipedRes user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfilePage(user: user, jobId: widget.jobId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 10.h, 20.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _dark,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interested Users',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Swipe right to match · left to skip',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // ── Card swiper ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: CardSwiper(
                  controller: _controller,
                  scale: 0.93,
                  padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
                  cardsCount: users.length,
                  numberOfCardsDisplayed: users.length.clamp(1, 3),
                  initialIndex: widget.initialIndex,
                  allowedSwipeDirection: const AllowedSwipeDirection.only(
                    left: true,
                    right: true,
                  ),
                  onSwipe: (prev, curr, dir) async {
                    if (dir == CardSwiperDirection.right) {
                      await _onMatch(users[prev]);
                    }
                    return true;
                  },
                  cardBuilder: (context, index, pctX, pctY) {
                    CardSwiperDirection? liveDir;
                    const threshold = 0.12;
                    if (pctX > threshold) liveDir = CardSwiperDirection.right;
                    if (pctX < -threshold) liveDir = CardSwiperDirection.left;
                    return _SwipeCard(
                      user: users[index],
                      liveDirection: liveDir,
                      onViewProfile: () => _viewProfile(users[index]),
                    );
                  },
                  isLoop: false,
                ),
              ),
            ),

            // ── FAB row ───────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: 28.h, top: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _fab(
                    icon: Icons.favorite_rounded,
                    color: _accept,
                    size: 64,
                    label: 'Match',
                    onTap: () => _controller.swipe(CardSwiperDirection.right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab({
    required IconData icon,
    required Color color,
    required double size,
    required String label,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size.w,
            height: size.w,
            decoration: BoxDecoration(
              color: outlined ? Colors.white : color,
              shape: BoxShape.circle,
              border: outlined
                  ? Border.all(color: Colors.grey.shade300, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: outlined
                      ? Colors.black.withOpacity(0.06)
                      : color.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: outlined ? Colors.grey.shade400 : Colors.white,
              size: size * 0.44,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: outlined ? Colors.grey : color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Swipe Card — card shown inside the swipe detail view
// ═══════════════════════════════════════════════════════════════════════════
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
            color: _navy.withOpacity(0.35),
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
              // ── Photo — top 62% ──────────────────────────────────────
              Expanded(
                flex: 62,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      user.profile,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _teal.withOpacity(0.08),
                        child: const Icon(
                          Icons.person_rounded,
                          color: _teal,
                          size: 64,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _navy.withOpacity(0.6),
                              _navy,
                            ],
                            stops: const [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info — bottom 38% ────────────────────────────────────
              Expanded(
                flex: 38,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      if (user.location.isNotEmpty) ...[
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: _orange,
                              size: 13,
                            ),
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
                      GestureDetector(
                        onTap: onViewProfile,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _teal.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                color: _teal,
                                size: 13,
                              ),
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
                      if (user.skills.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: user.skills.take(6).map((skill) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 11.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _teal.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _teal.withOpacity(0.25),
                                    width: 1,
                                  ),
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
                        )
                      else
                        Text(
                          'No skills listed',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white30,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Swipe overlay ──────────────────────────────────────────────
          if (hasOverlay)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: (isRight ? _accept : _reject).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: isRight ? _accept : _reject,
                    width: 2.5,
                  ),
                ),
                child: Align(
                  alignment: isRight ? Alignment.topRight : Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 28.h,
                      left: isLeft ? 20.w : 0,
                      right: isRight ? 20.w : 0,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Profile Page — full screen profile view
// ═══════════════════════════════════════════════════════════════════════════
class _ProfilePage extends StatefulWidget {
  final SwipedRes user;
  final String jobId;
  final VoidCallback? onMatched;

  const _ProfilePage({required this.user, required this.jobId, this.onMatched});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _orange = Color(0xFFf55631);
  static const Color _accept = Color(0xFF2DB67D);
  static const Color _reject = Color(0xFFE8505B);

  bool _isMatching = false;

  Future<void> _onMatch() async {
    setState(() => _isMatching = true);

    Provider.of<JobsNotifier>(
      context,
      listen: false,
    ).addMatchedUsers(widget.jobId, widget.user.id);

    Get.snackbar(
      "It's a Match!",
      "You matched with ${widget.user.username}",
      backgroundColor: _accept,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.favorite, color: Colors.white),
      duration: const Duration(seconds: 3),
    );

    final result = await ChatHelper.createChat(
      CreateChat(userId: widget.user.id),
    );
    if (!mounted) return;

    setState(() => _isMatching = false);

    if (result['success'] == true) {
      final chatId = result['chatId'] as String;
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId') ?? '';
      widget.onMatched?.call();
      Get.to(
        () => ChatPage(
          id: chatId,
          title: widget.user.username,
          profile: widget.user.profile,
          user: [currentUserId, widget.user.id],
        ),
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to create chat',
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
            onTap: _isMatching ? null : _onMatch,
            child: Container(
              height: 54.h,
              decoration: BoxDecoration(
                color: _accept,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _accept.withOpacity(0.4),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  widget.user.profile,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _teal.withOpacity(0.1),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _teal,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              widget.user.username,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            if (widget.user.location.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: _orange,
                    size: 15,
                  ),
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
            if (widget.user.skills.isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                'SKILLS',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.user.skills.map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _teal.withOpacity(0.3),
                        width: 1,
                      ),
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
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
