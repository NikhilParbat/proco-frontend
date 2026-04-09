import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkDetailPage extends StatefulWidget {
  final AllBookmark bookmark;
  const BookmarkDetailPage({required this.bookmark, super.key});

  @override
  State<BookmarkDetailPage> createState() => _BookmarkDetailPageState();
}

class _BookmarkDetailPageState extends State<BookmarkDetailPage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _tealLt = Color(0xFF0BBFCA);
  static const Color _orange = Color(0xFFf55631);
  static const Color _red = Color(0xFFD23838);
  static const Color _green = Color(0xFF089F20);

  late final CardSwiperController _controller;
  String _currentUserId = '';
  bool _actionTaken = false;

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _currentUserId = prefs.getString('userId') ?? '');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAction(CardSwiperDirection direction) {
    if (_actionTaken) return;
    _actionTaken = true;

    final job = widget.bookmark.job;
    final jobsNotifier = context.read<JobsNotifier>();
    final bookmarkNotifier = context.read<BookMarkNotifier>();

    if (direction == CardSwiperDirection.right) {
      // Interested — record as right-swipe (match candidate)
      jobsNotifier.addSwipedUsers(job.id, _currentUserId, 'right');
    }

    // Both left and right: remove from bookmarks
    bookmarkNotifier.deleteBookMark(job.id);

    Future.delayed(const Duration(milliseconds: 350), () {
      bookmarkNotifier.getBookMarks();
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.bookmark.job;

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved Query',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Swipeable card ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: CardSwiper(
                controller: _controller,
                cardsCount: 1,
                numberOfCardsDisplayed: 1,
                isLoop: false,
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                ),
                onSwipe: (prev, curr, direction) {
                  _handleAction(direction);
                  return true;
                },
                cardBuilder: (context, index, pctX, pctY) {
                  CardSwiperDirection? liveDirection;
                  const threshold = 0.15;
                  if (pctX > threshold) {
                    liveDirection = CardSwiperDirection.right;
                  } else if (pctX < -threshold) {
                    liveDirection = CardSwiperDirection.left;
                  }
                  return _buildCard(j, liveDirection);
                },
              ),
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(48.w, 0, 48.w, 36.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(
                  icon: Icons.close_rounded,
                  color: _red,
                  label: 'Pass',
                  onTap: () => _controller.swipe(CardSwiperDirection.left),
                ),
                _actionButton(
                  icon: Icons.star_rounded,
                  color: _green,
                  label: 'Apply',
                  onTap: () => _controller.swipe(CardSwiperDirection.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(Job j, CardSwiperDirection? liveDirection) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.4),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top image
              Expanded(
                flex: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      j.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _teal.withOpacity(0.12),
                        child: const Icon(
                          Icons.business_rounded,
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
                              _navy.withOpacity(0.85),
                            ],
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
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

              // Bottom info
              Expanded(
                flex: 48,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 12.h,
                  ),
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
                          const Icon(
                            Icons.location_on_rounded,
                            color: _orange,
                            size: 13,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              j.location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white60,
                                fontFamily: 'Poppins',
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
                            const Icon(
                              Icons.payments_outlined,
                              color: _tealLt,
                              size: 13,
                            ),
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
      ],
    );
  }

  // ─── Swipe overlay ────────────────────────────────────────────────────────
  Widget _buildSwipeOverlay(CardSwiperDirection direction) {
    final isLeft = direction == CardSwiperDirection.left;
    final Color color = isLeft ? _red : _green;
    final IconData icon = isLeft ? Icons.close_rounded : Icons.star_rounded;
    final String label = isLeft ? 'PASS' : 'APPLY';
    final Alignment alignment = isLeft ? Alignment.topLeft : Alignment.topRight;
    final EdgeInsets padding = isLeft
        ? EdgeInsets.only(top: 30.h, left: 22.w)
        : EdgeInsets.only(top: 30.h, right: 22.w);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
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

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
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
