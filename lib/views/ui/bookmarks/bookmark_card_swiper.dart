import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:proco/views/ui/bookmarks/bookmark_detail_page.dart';
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
  static const Color _navy   = Color(0xFF040326);
  static const Color _teal   = Color(0xFF08979F);
  static const Color _tealLt = Color(0xFF0BBFCA);
  static const Color _orange = Color(0xFFf55631);
  static const Color _red    = Color(0xFFD23838);
  static const Color _green  = Color(0xFF089F20);

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
    if (mounted) setState(() => _currentUserId = prefs.getString('userId') ?? '');
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
    if (_isFinished || _bookmarks.isEmpty) return _buildFinishedState();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CardSwiper(
          key: ValueKey(_bookmarks.length),
          controller: _controller,
          scale: 0.5,
          cardsCount: _bookmarks.length,
          numberOfCardsDisplayed: _bookmarks.length.clamp(1, 2),
          allowedSwipeDirection: const AllowedSwipeDirection.only(
            left: true,
            right: true,
            up: true,
          ),
          isLoop: false,
          onEnd: () => setState(() => _isFinished = true),
          onSwipe: (previousIndex, currentIndex, direction) {
            final bookmark = _bookmarks[previousIndex];
            if (direction == CardSwiperDirection.left) {
              // Swipe left → remove bookmark
              widget.bookmarkNotifier.deleteBookMark(bookmark.job.id);
            } else if (direction == CardSwiperDirection.right ||
                direction == CardSwiperDirection.top) {
              if (direction == CardSwiperDirection.right &&
                  _currentUserId.isNotEmpty) {
                context
                    .read<JobsNotifier>()
                    .addSwipedUsers(bookmark.job.id, _currentUserId, 'right');
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookmarkDetailPage(bookmark: bookmark),
                ),
              );
            }
            return true;
          },
          cardBuilder: (context, index, pctX, pctY) {
            final bookmark = _bookmarks[index];
            CardSwiperDirection? liveDirection;
            const threshold = 0.15;
            if (index == 0) {
              if (pctY < -threshold) {
                liveDirection = CardSwiperDirection.top;
              } else if (pctX > threshold) {
                liveDirection = CardSwiperDirection.right;
              } else if (pctX < -threshold) {
                liveDirection = CardSwiperDirection.left;
              }
            }
            return _buildCard(bookmark, liveDirection);
          },
        ),
        Positioned(bottom: 48.h, child: _buildFabRow()),
      ],
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(AllBookmark bookmark, CardSwiperDirection? liveDirection) {
    final j = bookmark.job;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.4),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top image (44%) ──────────────────────────────────────────
              Expanded(
                flex: 44,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      j.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: _teal.withValues(alpha: 0.12),
                        child: const Icon(Icons.business_rounded, color: _teal, size: 64),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, _navy.withValues(alpha: 0.85)],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (j.hiring)
                      Positioned(
                        top: 14.h,
                        right: 14.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Actively Hiring',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    // Saved badge
                    Positioned(
                      top: 14.h,
                      left: 14.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: _teal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bookmark_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 4.w),
                            Text(
                              'Saved',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12.h,
                      left: 16.w,
                      right: 16.w,
                      child: Text(
                        j.company.isNotEmpty ? j.company : 'Unknown Company',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: _tealLt,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom info (56%) ────────────────────────────────────────
              Expanded(
                flex: 56,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 108.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: _orange, size: 13),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              j.location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (j.contract.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            _chip(j.contract, Colors.white12),
                          ],
                        ],
                      ),
                      if (j.salary.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: _tealLt, size: 13),
                            SizedBox(width: 4.w),
                            Text(
                              j.period.isNotEmpty
                                  ? '${j.salary} · ${j.period}'
                                  : j.salary,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _tealLt,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (liveDirection != null) _buildSwipeOverlay(liveDirection),
        // Delete button — always visible on every card
        Positioned(
          top: 12.h,
          right: 12.w,
          child: GestureDetector(
            onTap: () {
              widget.bookmarkNotifier.deleteBookMark(bookmark.job.id);
              setState(() {
                _bookmarks.remove(bookmark);
                if (_bookmarks.isEmpty) _isFinished = true;
              });
            },
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: _red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _red.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 15.sp),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Swipe overlay ────────────────────────────────────────────────────────
  Widget _buildSwipeOverlay(CardSwiperDirection direction) {
    final isLeft  = direction == CardSwiperDirection.left;
    final isRight = direction == CardSwiperDirection.right;

    final Color color  = isLeft ? _red : isRight ? _green : _teal;
    final IconData icon = isLeft
        ? Icons.bookmark_remove_rounded
        : isRight
        ? Icons.open_in_new_rounded
        : Icons.info_outline_rounded;
    final String label = isLeft ? 'REMOVE' : isRight ? 'VIEW' : 'DETAIL';
    final Alignment alignment = isLeft
        ? Alignment.topLeft
        : isRight
        ? Alignment.topRight
        : Alignment.topCenter;
    final EdgeInsets padding = isLeft
        ? EdgeInsets.only(top: 30.h, left: 22.w)
        : isRight
        ? EdgeInsets.only(top: 30.h, right: 22.w)
        : EdgeInsets.only(top: 22.h);

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _fab(
          icon: Icons.bookmark_remove_rounded,
          color: _red,
          label: 'Remove',
          onTap: () => _controller.swipe(CardSwiperDirection.left),
          size: 64,
        ),
        SizedBox(width: 14.w),
        _fab(
          icon: Icons.open_in_new_rounded,
          color: _green,
          label: 'View',
          onTap: () => _controller.swipe(CardSwiperDirection.right),
          size: 64,
        ),
        SizedBox(width: 14.w),
        _fab(
          icon: Icons.info_outline_rounded,
          color: _teal,
          label: 'Detail',
          onTap: () => _controller.swipe(CardSwiperDirection.top),
          size: 50,
        ),
      ],
    );
  }

  Widget _fab({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required double size,
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
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.44),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
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
              child: Icon(Icons.bookmark_border_rounded, size: 44.w, color: _teal),
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
