import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkCardSwiper extends StatefulWidget {
  final List<AllBookmark> bookmarks;
  final BookMarkNotifier bookmarkNotifier;

  const BookmarkCardSwiper({
    super.key,
    required this.bookmarks,
    required this.bookmarkNotifier,
  });

  @override
  State<BookmarkCardSwiper> createState() => _BookmarkCardSwiperState();
}

class _BookmarkCardSwiperState extends State<BookmarkCardSwiper> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _tealLt = Color(0xFF0BBFCA);
  static const Color _orange = Color(0xFFf55631);
  static const Color _red = Color(0xFFD23838);
  static const Color _green = Color(0xFF089F20);

  late final CardSwiperController _controller;
  late List<AllBookmark> _bookmarks;
  bool _isFinished = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
    _bookmarks = List.from(widget.bookmarks);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _currentUserId = prefs.getString('userId') ?? '');
  }

  @override
  void didUpdateWidget(BookmarkCardSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookmarks.length != _bookmarks.length) {
      setState(() => _bookmarks = List.from(widget.bookmarks));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished || _bookmarks.isEmpty) {
      return _buildFinishedState();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 26.h),

      child: Column(
        children: [
          Expanded(
            child: CardSwiper(
              key: ValueKey(_bookmarks.length),

              controller: _controller,

              cardsCount: _bookmarks.length,

              scale: 0.92,

              numberOfCardsDisplayed: _bookmarks.length.clamp(1, 2),

              backCardOffset: const Offset(0, 18),

              padding: EdgeInsets.zero,

              allowedSwipeDirection: const AllowedSwipeDirection.only(
                left: true,
                right: true,
              ),

              isLoop: false,

              onEnd: () => setState(() => _isFinished = true),

              onSwipe: (previousIndex, currentIndex, direction) async {
                final bookmark = _bookmarks[previousIndex];

                // ✅ Remove bookmark for BOTH directions
                await widget.bookmarkNotifier.deleteBookMark(bookmark.job.id);

                // ✅ Remove locally for immediate UI update
                setState(() {
                  _bookmarks.removeAt(previousIndex);

                  if (_bookmarks.isEmpty) {
                    _isFinished = true;
                  }
                });

                // ✅ Right swipe action
                if (direction == CardSwiperDirection.right) {
                  if (_currentUserId.isNotEmpty) {
                    context.read<JobsNotifier>().addSwipedUsers(
                      bookmark.job.id,
                      _currentUserId,
                      'right',
                    );
                  }

                  Get.snackbar(
                    'Swiped!',
                    'You swiped on ${bookmark.job.company.isNotEmpty ? bookmark.job.company : bookmark.job.title}',
                    colorText: kLight,
                    backgroundColor: const Color(0xFF089F20),
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                    ),
                    duration: const Duration(seconds: 2),
                  );
                }

                return true;
              },

              cardBuilder: (context, index, pctX, pctY) {
                final bookmark = _bookmarks[index];

                CardSwiperDirection? liveDirection;

                const threshold = 0.15;

                if (index == 0) {
                  if (pctX > threshold) {
                    liveDirection = CardSwiperDirection.right;
                  } else if (pctX < -threshold) {
                    liveDirection = CardSwiperDirection.left;
                  }
                }

                return _buildCard(bookmark, liveDirection);
              },
            ),
          ),

          SizedBox(height: 18.h),

          _buildFabRow(),
        ],
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(AllBookmark bookmark, CardSwiperDirection? liveDirection) {
    final j = bookmark.job;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── IMAGE ─────────────────────────────
              Expanded(
                flex: 46,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      j.imageUrl,
                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) => Container(
                        color: kThemeColor.withOpacity(0.08),
                        child: Icon(
                          Icons.work_outline_rounded,
                          color: kThemeColor,
                          size: 56.sp,
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
                              Colors.black.withOpacity(0.55),
                            ],
                            stops: const [0.55, 1],
                          ),
                        ),
                      ),
                    ),

                    // ── Saved Badge ─────────────────
                    Positioned(
                      top: 16.h,
                      left: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              size: 13.sp,
                              color: kThemeColor,
                            ),

                            SizedBox(width: 5.w),

                            Text(
                              'Saved',
                              style: TextStyle(
                                fontFamily: kFontDMSans,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: kThemeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Hiring Badge ────────────────
                    if (j.hiring)
                      Positioned(
                        top: 16.h,
                        right: 16.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(24.r),
                          ),

                          child: Text(
                            'Hiring',
                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // ── Company ─────────────────────
                    Positioned(
                      left: 18.w,
                      right: 18.w,
                      bottom: 18.h,

                      child: Text(
                        j.company.isNotEmpty ? j.company : 'Unknown Company',

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom info ────────────────────────────────────────
              Expanded(
                flex: 56,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 36.h),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ─────────────────────────────
                      Text(
                        j.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontFamily: kFontMontserrat,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // ── Location ──────────────────────────
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16.sp,
                            color: kThemeColor,
                          ),

                          SizedBox(width: 5.w),

                          Expanded(
                            child: Text(
                              j.location,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                fontFamily: kFontDMSans,
                                fontSize: 13.sp,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // ── Salary ────────────────────────────
                      if (j.salary.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 16.sp,
                              color: kThemeColor,
                            ),

                            SizedBox(width: 5.w),

                            Expanded(
                              child: Text(
                                j.period.isNotEmpty
                                    ? '${j.salary} · ${j.period}'
                                    : j.salary,

                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  fontFamily: kFontDMSans,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: kThemeColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 14.h),

                      // ── Contract Type ─────────────────────
                      if (j.contract.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 7.h,
                          ),

                          decoration: BoxDecoration(
                            color: kThemeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20.r),
                          ),

                          child: Text(
                            j.contract,

                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: kThemeColor,
                            ),
                          ),
                        ),

                      const Spacer(),

                      // ── Swipe Hint ────────────────────────
                      Center(
                        child: Text(
                          'Swipe or use the buttons below',
                          style: TextStyle(
                            fontFamily: kFontDMSans,
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Swipe Overlay ─────────────────────────
        if (liveDirection != null) _buildSwipeOverlay(liveDirection),
      ],
    );
  }

  // ─── Swipe overlay ────────────────────────────────────────────────────────
  Widget _buildSwipeOverlay(CardSwiperDirection direction) {
    final isLeft = direction == CardSwiperDirection.left;

    final Color color = isLeft ? _red : _green;
    final IconData icon = isLeft
        ? Icons.bookmark_remove_rounded
        : Icons.favorite_rounded;
    final String label = isLeft ? 'REMOVE' : 'MATCH';
    final Alignment alignment = isLeft ? Alignment.topLeft : Alignment.topRight;
    final EdgeInsets padding = isLeft
        ? EdgeInsets.only(top: 30.h, left: 22.w)
        : EdgeInsets.only(top: 30.h, right: 22.w);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: color, width: 3),
        ),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: padding,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.sp,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── FAB row ──────────────────────────────────────────────────────────────
  Widget _buildFabRow() {
    return SizedBox(
      width: 260.w,
      height: 82.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Remove ─────────────────────────────
          _modernActionButton(
            icon: Icons.close_rounded,
            iconColor: Colors.black87,
            backgroundColor: Colors.white,
            size: 68,
            onTap: () => _controller.swipe(CardSwiperDirection.left),
          ),

          // ── Match ──────────────────────────────
          _modernActionButton(
            icon: Icons.favorite_rounded,
            iconColor: kThemeColor,
            backgroundColor: Colors.white,
            size: 72,
            onTap: () => _controller.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _modernActionButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        width: size.w,
        height: size.w,

        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),

            BoxShadow(
              color: Colors.white.withOpacity(0.45),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
        ),

        child: Center(
          child: Icon(icon, color: iconColor, size: size * 0.42),
        ),
      ),
    );
  }

  // ─── Finished state ────────────────────────────────────────────────────────
  Widget _buildFinishedState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 44.w,
                color: _teal,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'All caught up!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'You\'ve reviewed all your saved jobs.\nSwipe up on a job card on the home screen to save more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white54,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
