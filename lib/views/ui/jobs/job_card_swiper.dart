import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const Color _teal = Color(0xFF08979F);
  static const Color _red = Color(0xFFD23838);
  static const Color _green = Color(0xFF089F20);

  bool isExpanded(String id) {
    return _expandedDesc[id] ?? false;
  }

  void toggleExpanded(String id) {
    setState(() {
      _expandedDesc[id] = !(_expandedDesc[id] ?? false);
    });
  }

  late final int _imageCacheWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _imageCacheWidth = (MediaQuery.of(context).size.width * 1.2).toInt();
  }

  /// When the fraction of remaining cards drops to or below this value,
  /// the next page is silently prefetched. 0.25 = 25% remaining.
  static const double _prefetchThreshold = 0.25;

  late final CardSwiperController _controller;

  // Local copy so we can append new pages without resetting the swiper
  late List<JobsResponse> _jobs;
  bool _isFinished = false;

  // Tracks which job descriptions are expanded ("Read more" state)
  final Map<String, bool> _expandedDesc = {};

  // One undo at a time — like Hinge. Must swipe before undoing again.
  bool _canUndo = false;
  String? _lastSwipedJobId; // track last swiped job for backend undo

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
    _jobs = widget.jobs;
  }

  /// When the parent pushes more cards (next page loaded), append them
  /// to the local list. The swiper keeps its current position.
  @override
  void didUpdateWidget(JobCardSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jobs.length > _jobs.length) {
      _expandedDesc.removeWhere(
        (key, _) => !widget.jobs.any((j) => j.id == key),
      );
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

    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    double fw(double v) => sw * v / 678.0;
    double fh(double v) => sh * v / 1440.0;

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // ── Card swiper (isolated repaint) ────────────────────────────────────
          RepaintBoundary(
            child: CardSwiper(
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

                // ── Swipe actions ───────────────────────────────────────────────
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

                // ── Undo state ─────────────────────────────────────────────────
                setState(() {
                  _canUndo = true;
                  _lastSwipedJobId = job.id;
                });

                // ── Prefetch next page (non-blocking) ──────────────────────────
                final remaining = _jobs.length - previousIndex - 1;
                final fractionRemaining = remaining / _jobs.length;

                if (fractionRemaining <= _prefetchThreshold &&
                    !widget.jobNotifier.isFetchingMore &&
                    widget.jobNotifier.hasMorePages) {
                  Future.microtask(() {
                    widget.jobNotifier.loadNextPage(
                      widget.currentUserId,
                      bookmarkedIds: widget.bookmarkNotifier.jobs,
                    );
                  });
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

                // Card ends at Figma Y=1222 (1222/1440 of screen height).
                // Bottom padding leaves fh(218) below the card so the
                // button group can straddle the card's bottom border.
                return Padding(
                  padding: EdgeInsets.only(
                    left: sw * 2 / 678,
                    right: sw * 2 / 678,
                    bottom: fh(218),
                  ),
                  child: _buildCard(job, liveDirection),
                );
              },
            ),
          ),

          // ── Button Group SVG — center at card bottom edge (fh(218) from screen bottom)
          // button center = fh(218), height = fh(133) → bottom = fh(218 - 66.5) = fh(151.5)
          Positioned(
            left: fw(48),
            bottom: fh(151.5),
            width: fw(582),
            height: fh(133),
            child: _buildButtonGroup(fw, fh),
          ),
        ],
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────
  // Figma card: 609×1222. Image: canvas X=94→left=16, Y=39 (card-local), W=580, H=498.
  Widget _buildCard(JobsResponse job, CardSwiperDirection? liveDirection) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cw = constraints.maxWidth;
        final ch = constraints.maxHeight;
        double cfx(double v) => cw * v / 609.0;
        double cfy(double v) => ch * v / 1222.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gap above image (Y=39 within card)
                  SizedBox(height: cfy(39)),

                  // Image area: W=580, H=498; left=16, right=13 within card
                  Container(
                    height: cfy(498),
                    margin: EdgeInsets.only(left: cfx(16), right: cfx(13)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: job.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, _) => Container(
                            color: const Color(
                              0xFF08979F,
                            ).withValues(alpha: 0.08),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (ctx, _, _) => Container(
                            color: const Color(
                              0xFF08979F,
                            ).withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.business_rounded,
                              color: Color(0xFF08979F),
                              size: 48,
                            ),
                          ),
                          memCacheWidth: _imageCacheWidth,
                        ),
                        if (job.opportunityType.isNotEmpty)
                          Positioned(
                            left: 12.w,
                            top: 14.h,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/ot.svg',
                                  width: 90.w,
                                  height: 23.h,
                                  fit: BoxFit.fill,
                                ),
                                Text(
                                  job.opportunityType.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Positioned(
                          right: 8.w,
                          top: 8.h,
                          child: SvgPicture.asset(
                            'assets/userbox.svg',
                            width: 82.w,
                            height: 50.h,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content section (remainder of card height)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        cfx(16),
                        cfy(12),
                        cfx(16),
                        cfy(108),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 20.sp,
                              color: const Color(0xFF0B0D13),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (job.domain.isNotEmpty) ...[
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/domain.svg',
                                  height: 26.h,
                                  fit: BoxFit.fitHeight,
                                ),
                                Text(
                                  job.domain,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                          ],
                          if (job.location.isNotEmpty) ...[
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/location.svg',
                                  width: 10.w,
                                  height: 14.h,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    'Opportunity Location: ${job.location}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF666666),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                          ],
                          if (job.description.isNotEmpty) ...[
                            Text(
                              job.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11.sp,
                                color: const Color(0xFF555555),
                                height: 1.45,
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],
                          if (job.requirements.isNotEmpty) ...[
                            Text(
                              'Requirements',
                              style: GoogleFonts.dmSans(
                                fontSize: 13.sp,
                                color: const Color(0xFFA195B5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            ...job.requirements
                                .take(3)
                                .map(
                                  (req) => Padding(
                                    padding: EdgeInsets.only(bottom: 3.h),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 5.h),
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF555555),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: Text(
                                            req,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11.sp,
                                              color: const Color(0xFF555555),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
      },
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

  // ─── Button Group SVG ────────────────────────────────────────────────────
  // SVG viewBox: 590×143. Button centres at x ≈ 30, 173, 315, 458.
  // Tap-area splits at midpoints: 101, 244, 386.
  // Order (L→R): heart/apply, X/pass, bookmark/save, back/undo.
  Widget _buildButtonGroup(
    double Function(double) fw,
    double Function(double) fh,
  ) {
    final totalW = fw(582);
    final totalH = fh(133);

    const splits = [0.0, 101 / 590, 244 / 590, 386 / 590, 1.0];

    final tapActions = <VoidCallback>[
      () => _controller.swipe(CardSwiperDirection.right),
      () => _controller.swipe(CardSwiperDirection.left),
      () => _controller.swipe(CardSwiperDirection.top),
      () {
        if (!_canUndo) return;
        _controller.undo();
        if (_lastSwipedJobId != null) {
          widget.jobNotifier.undoSwipe(_lastSwipedJobId!, widget.currentUserId);
        }
        setState(() {
          _canUndo = false;
          _lastSwipedJobId = null;
        });
      },
    ];

    return Stack(
      children: [
        SvgPicture.asset(
          'assets/Button Group.svg',
          width: totalW,
          height: totalH,
          fit: BoxFit.fill,
        ),
        ...List.generate(4, (i) {
          final leftFrac = splits[i];
          final rightFrac = splits[i + 1];
          return Positioned(
            left: leftFrac * totalW,
            top: 0,
            width: (rightFrac - leftFrac) * totalW,
            height: totalH,
            child: GestureDetector(
              onTap: tapActions[i],
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          );
        }),
      ],
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
                color: _teal.withValues(alpha: 0.12),
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
}
