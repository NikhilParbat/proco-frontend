import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/request/bookmarks/bookmarks_model.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';

class JobCardSwiper extends StatefulWidget {
  final List<JobsResponse> jobs;
  final String currentUserId;
  final JobsNotifier jobNotifier;
  final BookMarkNotifier bookmarkNotifier;

  const JobCardSwiper({
    super.key,
    required this.jobs,
    required this.currentUserId,
    required this.jobNotifier,
    required this.bookmarkNotifier,
  });

  @override
  State<JobCardSwiper> createState() => _JobCardSwiperState();
}

class _JobCardSwiperState extends State<JobCardSwiper> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _tealLt = Color(0xFF0BBFCA);
  static const Color _orange = Color(0xFFf55631);
  static const Color _red = Color(0xFFD23838);
  static const Color _green = Color(0xFF089F20);

  /// When the fraction of remaining cards drops to or below this value,
  /// the next page is silently prefetched. 0.25 = 25% remaining.
  static const double _prefetchThreshold = 0.25;

  late final CardSwiperController _controller;

  // Local copy so we can append new pages without resetting the swiper
  late List<JobsResponse> _jobs;
  bool _isFinished = false;

  // One undo at a time — like Hinge. Must swipe before undoing again.
  bool _canUndo = false;
  String? _lastSwipedJobId; // track last swiped job for backend undo

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
    _jobs = List.from(widget.jobs);
  }

  /// When the parent pushes more cards (next page loaded), append them
  /// to the local list. The swiper keeps its current position.
  @override
  void didUpdateWidget(JobCardSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jobs.length > _jobs.length) {
      setState(() => _jobs = List.from(widget.jobs));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildFinishedState();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // ── Card swiper ──────────────────────────────────────────────────────
        CardSwiper(
          controller: _controller,
          scale: 0.5,
          cardsCount: _jobs.length,
          numberOfCardsDisplayed: _jobs.length.clamp(1, 2),
          allowedSwipeDirection: const AllowedSwipeDirection.only(
            left: true,
            right: true,
            up: true,
          ),
          isLoop: false,
          onEnd: () => setState(() => _isFinished = true),
          onSwipe: (previousIndex, currentIndex, direction) {
            final job = _jobs[previousIndex];
            if (direction == CardSwiperDirection.right) {
              widget.jobNotifier.addSwipedUsers(
                job.id,
                widget.currentUserId,
                'right',
              );
            } else if (direction == CardSwiperDirection.left) {
              widget.jobNotifier.addSwipedUsers(
                job.id,
                widget.currentUserId,
                'left',
              );
            } else if (direction == CardSwiperDirection.top) {
              widget.bookmarkNotifier.addBookMark(
                BookmarkReqResModel(job: job.id),
                job.id,
              );
            }

            // Swiped forward — undo is available again
            setState(() {
              _canUndo = true;
              _lastSwipedJobId = job.id;
            });

            // Prefetch next page when remaining cards fall below threshold
            final remaining = _jobs.length - previousIndex - 1;
            final fractionRemaining = remaining / _jobs.length;
            if (fractionRemaining <= _prefetchThreshold &&
                !widget.jobNotifier.isFetchingMore &&
                widget.jobNotifier.hasMorePages) {
              widget.jobNotifier.loadNextPage(
                widget.currentUserId,
                bookmarkedIds: widget.bookmarkNotifier.jobs,
              );
            }

            return true;
          },
          cardBuilder: (context, index, pctX, pctY) {
            final job = _jobs[index];
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
            return _buildCard(job, liveDirection);
          },
        ),

        // ── Floating action buttons ──────────────────────────────────────────
        Positioned(bottom: 48.h, child: _buildFabRow()),
      ],
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard(JobsResponse job, CardSwiperDirection? liveDirection) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha:0.4),
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
                      job.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: _teal.withValues(alpha:0.12),
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
                              _navy.withValues(alpha:0.85),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (job.hiring)
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
                        job.company.isNotEmpty
                            ? job.company
                            : 'Unknown Company',
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
                        job.title,
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
                              job.location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors
                                    .white70, // Slightly brighter for readability
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (job.contract.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            _chip(job.contract, Colors.white12),
                          ],
                        ],
                      ),
                      SizedBox(height: 8.h),
                      if (job.domain.isNotEmpty ||
                          job.opportunityType.isNotEmpty)
                        Row(
                          children: [
                            if (job.domain.isNotEmpty)
                              _chip(job.domain, _teal.withValues(alpha:0.35)),
                            if (job.domain.isNotEmpty &&
                                job.opportunityType.isNotEmpty)
                              SizedBox(width: 6.w),
                            if (job.opportunityType.isNotEmpty)
                              _chip(
                                job.opportunityType,
                                _teal.withValues(alpha:0.35),
                              ),
                          ],
                        ),
                      if (job.domain.isNotEmpty ||
                          job.opportunityType.isNotEmpty)
                        SizedBox(height: 8.h),
                      if (job.salary.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: _tealLt,
                              size: 13,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              job.period.isNotEmpty
                                  ? '${job.salary} · ${job.period}'
                                  : job.salary,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _tealLt,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      if (job.salary.isNotEmpty) SizedBox(height: 8.h),
                      if (job.description.isNotEmpty) ...[
                        Text(
                          job.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      ...job.requirements
                          .take(2)
                          .map(
                            (req) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 5.h),
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: _teal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      req,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.white60,
                                        fontFamily: 'Poppins',
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
    final isRight = direction == CardSwiperDirection.right;

    final Color color = isLeft
        ? _red
        : isRight
        ? _green
        : _teal;
    final IconData icon = isLeft
        ? Icons.close_rounded
        : isRight
        ? Icons.star_rounded
        : Icons.bookmark_rounded;
    final String label = isLeft
        ? 'PASS'
        : isRight
        ? 'APPLY'
        : 'SAVE';
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
          color: color.withValues(alpha:0.15),
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
          icon: Icons.rotate_left_rounded,
          color: _canUndo ? _teal : Colors.white24,
          label: 'Undo',
          onTap: _canUndo
              ? () {
                  _controller.undo();
                  if (_lastSwipedJobId != null) {
                    widget.jobNotifier.undoSwipe(
                      _lastSwipedJobId!,
                      widget.currentUserId,
                    );
                  }
                  setState(() {
                    _canUndo = false;
                    _lastSwipedJobId = null;
                  });
                }
              : () {},
          size: 50,
        ),
        SizedBox(width: 14.w),
        _fab(
          icon: Icons.close_rounded,
          color: _red,
          label: 'Pass',
          onTap: () => _controller.swipe(CardSwiperDirection.left),
          size: 64,
        ),
        SizedBox(width: 14.w),
        _fab(
          icon: Icons.star_rounded,
          color: _green,
          label: 'Apply',
          onTap: () => _controller.swipe(CardSwiperDirection.right),
          size: 64,
        ),
        SizedBox(width: 14.w),
        _fab(
          icon: Icons.bookmark_rounded,
          color: _teal,
          label: 'Save',
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
                // top-edge highlight — gives the raised dome feel
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
                // coloured glow
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                // hard dark base — the "depth" layer
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

  // ─── No more cards state ──────────────────────────────────────────────────
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
                color: _teal.withValues(alpha:0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.coffee_rounded, size: 44.w, color: _teal),
            ),
            SizedBox(height: 24.h),
            Text(
              'You\'re all caught up!',
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
              'Come back later for more opportunities.\nNew listings are added regularly.',
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

  // ─── Chip ─────────────────────────────────────────────────────────────────
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
