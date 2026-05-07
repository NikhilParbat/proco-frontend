import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/bookmarks/bookmarks_model.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
                  padding: EdgeInsets.only(left: 0, right: 0, bottom: fh(50)),
                  child: _buildCard(job, liveDirection),
                );
              },
            ),
          ),

          // ── Button Group SVG — center at card bottom edge (fh(218) from screen bottom)
          // button center = fh(218), height = fh(133) → bottom = fh(218 - 66.5) = fh(151.5)
          Positioned(
            left: fw(48),
            bottom: fh(40),
            width: fw(582),
            height: fh(133),
            child: _buildButtonGroup(fw, fh),
          ),
        ],
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────
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
                  color: Colors.black.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image – full-width, flush to card top ──────────────
                  SizedBox(
                    height: cfy(498),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: job.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, _) => Container(
                            color: kThemeColor.withValues(alpha: 0.06),
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
                            color: kThemeColor.withValues(alpha: 0.06),
                            child: const Icon(
                              Icons.business_rounded,
                              color: kThemeColor,
                              size: 48,
                            ),
                          ),
                          memCacheWidth: _imageCacheWidth,
                        ),
                        // Opportunity-type badge – icon + text
                        if (job.opportunityType.isNotEmpty)
                          Positioned(
                            left: 14.w,
                            top: 14.h,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: kThemeColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_center,
                                    color: Colors.white,
                                    size: 12.w,
                                  ),
                                  SizedBox(width: 5.w),
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
                          ),
                        // Creator box – top right
                        Positioned(
                          right: 10.w,
                          top: 10.h,
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

                  // ── Content ────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        cfx(20),
                        cfy(14),
                        cfx(20),
                        cfy(100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 26.sp,
                              color: const Color(0xFF0B0D13),
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          if (job.company.isNotEmpty ||
                              job.domain.isNotEmpty) ...[
                            Row(
                              children: [
                                if (job.company.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      job.company,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF666666),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                if (job.company.isNotEmpty &&
                                    job.domain.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                    ),
                                    child: Container(
                                      width: 4.w,
                                      height: 4.w,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFBBBBBB),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                if (job.domain.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      job.domain,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.sp,
                                        color: kThemeColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            SizedBox(height: 8.h),
                          ],

                          // Opportunity Location
                          if (job.location.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.public_outlined,
                                  size: 14.w,
                                  color: const Color(0xFF999999),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Location: ',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11.sp,
                                            color: kThemeColor,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        TextSpan(
                                          text: job.location,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11.sp,
                                            color: const Color(0xFF1A1A2E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                          ],

                          if (job.experienceLevel.isNotEmpty ||
                              job.contract.isNotEmpty ||
                              job.salary.isNotEmpty) ...[
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: [
                                if (job.experienceLevel.isNotEmpty)
                                  _buildInfoChip(job.experienceLevel),

                                if (job.contract.isNotEmpty)
                                  _buildInfoChip(job.contract),

                                if (job.salary.isNotEmpty)
                                  _buildInfoChip(job.salary),
                              ],
                            ),

                            SizedBox(height: 10.h),
                          ],

                          // Description + Read more
                          if (job.description.isNotEmpty) ...[
                            Text(
                              job.description,
                              maxLines: isExpanded(job.id) ? null : 2,
                              overflow: isExpanded(job.id)
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11.sp,
                                color: const Color(0xFF444444),
                                height: 1.5,
                              ),
                            ),
                            if (!isExpanded(job.id))
                              GestureDetector(
                                onTap: () => toggleExpanded(job.id),
                                child: Text(
                                  '... Read more',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.sp,
                                    color: kThemeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(height: 12.h),
                          ],

                          // Requirements
                          if (job.requirements.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 26.w,
                                  height: 26.w,
                                  decoration: const BoxDecoration(
                                    color: kThemeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14.w,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Requirements',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13.sp,
                                    color: kThemeColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            ...job.requirements
                                .take(4)
                                .map(
                                  (req) => Padding(
                                    padding: EdgeInsets.only(bottom: 4.h),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF555555),
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
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11.sp,
                                              color: const Color(0xFF444444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            SizedBox(height: 10.h),
                          ],

                          // Skills
                          if (job.skills.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 26.w,
                                  height: 26.w,
                                  decoration: const BoxDecoration(
                                    color: kThemeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.code,
                                    color: Colors.white,
                                    size: 14.w,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Skills',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13.sp,
                                    color: kThemeColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 6.h,
                              children: job.skills
                                  .take(6)
                                  .map(
                                    (skill) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFCCCCCC),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: Text(
                                        skill,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
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

  Widget _buildInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 10.sp,
          color: const Color(0xFF555555),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Button Group ────────────────────────────────────────────────────────
  Widget _buildButtonGroup(
    double Function(double) fw,
    double Function(double) fh,
  ) {
    final totalW = fw(582);
    final totalH = fh(133);
    final heartDiameter = totalH;
    final smallDiameter = totalH * 0.85;

    Widget buildBtn({
      required Widget icon,
      required Color bgColor,
      required double diameter,
      required VoidCallback? onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.45),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      );
    }

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// REVERT
          buildBtn(
            icon: Icon(
              Icons.reply_rounded,
              color: _canUndo
                  ? const Color(0xFF666666)
                  : const Color(0xFFBBBBBB),
              size: 24.sp,
            ),
            bgColor: const Color(0xFFF2F2F2),
            diameter: smallDiameter,
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
                : null,
          ),

          /// CANCEL
          buildBtn(
            icon: Icon(CupertinoIcons.xmark, color: Colors.black, size: 32.sp),
            bgColor: Colors.white,
            diameter: heartDiameter,
            onTap: () => _controller.swipe(CardSwiperDirection.left),
          ),

          /// HEART
          buildBtn(
            icon: PhosphorIcon(
              PhosphorIcons.heartStraight(),
              color: const Color(0xFFE6B8A2),
              size: 34.sp,
            ),
            bgColor: Colors.white,
            diameter: heartDiameter,
            onTap: () => _controller.swipe(CardSwiperDirection.right),
          ),

          /// BOOKMARK
          buildBtn(
            icon: Icon(
              CupertinoIcons.bookmark,
              color: Colors.white,
              size: 24.sp,
            ),
            bgColor: const Color(0xFF1E293B),
            diameter: smallDiameter,
            onTap: () => _controller.swipe(CardSwiperDirection.top),
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
