import 'dart:math' show pi;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/constants/app_text_styles.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:proco/views/common/skill_chips_wrap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  bool isExpanded(String id) => _expandedDesc[id] ?? false;

  void toggleExpanded(String id) {
    setState(() => _expandedDesc[id] = !(_expandedDesc[id] ?? false));
  }

  late final int _imageCacheWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _imageCacheWidth = (MediaQuery.of(context).size.width * 1.2).toInt();
  }

  late final CardSwiperController _controller;
  late List<AllBookmark> _bookmarks;
  bool _isFinished = false;
  final Map<String, bool> _expandedDesc = {};
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
    if (mounted) {
      setState(() => _currentUserId = prefs.getString('userId') ?? '');
    }
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
          RepaintBoundary(
            child: CardSwiper(
              controller: _controller,
              scale: 0.5,
              cardsCount: _bookmarks.length,
              numberOfCardsDisplayed: _bookmarks.length.clamp(1, 2),
              allowedSwipeDirection: const AllowedSwipeDirection.only(
                left: true,
                right: true,
              ),
              isLoop: false,
              onEnd: () => setState(() => _isFinished = true),
              onSwipe: (previousIndex, currentIndex, direction) async {
                final bookmark = _bookmarks[previousIndex];

                await widget.bookmarkNotifier.deleteBookMark(bookmark.job.id);

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

                setState(() {
                  _bookmarks.removeAt(previousIndex);
                  if (_bookmarks.isEmpty) _isFinished = true;
                });

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

                return Padding(
                  padding: EdgeInsets.only(bottom: fh(50)),
                  child: Stack(
                    children: [
                      _FlippableBookmarkCard(
                        bookmark: bookmark,
                        imageCacheWidth: _imageCacheWidth,
                        isExpanded: isExpanded(bookmark.job.id),
                        onToggleExpanded: () => toggleExpanded(bookmark.job.id),
                      ),
                      if (liveDirection != null)
                        _buildSwipeOverlay(liveDirection),
                    ],
                  ),
                );
              },
            ),
          ),

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

  Widget _buildSwipeOverlay(CardSwiperDirection _) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGroup(
    double Function(double) fw,
    double Function(double) fh,
  ) {
    final totalH = fh(133);
    final totalW = fw(582);
    final heartDiameter = totalH;

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
          buildBtn(
            icon: Icon(CupertinoIcons.xmark, color: Colors.black, size: 32.sp),
            bgColor: Colors.white,
            diameter: heartDiameter,
            onTap: () => _controller.swipe(CardSwiperDirection.left),
          ),
          buildBtn(
            icon: PhosphorIcon(
              PhosphorIcons.heartStraight(),
              color: kSend,
              size: 34.sp,
            ),
            bgColor: Colors.white,
            diameter: heartDiameter,
            onTap: () => _controller.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              color: kThemeColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 42.w,
              color: kThemeColor,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontFamily: kFontDMSans,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'You\'ve reviewed all your saved jobs.\nSwipe up on a job card on the home screen to save more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey,
              fontFamily: kFontDMSans,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Flippable Bookmark Card ──────────────────────────────────────────────────

class _FlippableBookmarkCard extends StatefulWidget {
  final AllBookmark bookmark;
  final int imageCacheWidth;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const _FlippableBookmarkCard({
    required this.bookmark,
    required this.imageCacheWidth,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  State<_FlippableBookmarkCard> createState() => _FlippableBookmarkCardState();
}

class _FlippableBookmarkCardState extends State<_FlippableBookmarkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showingBack = false;
  String? _ownerName;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    // _fetchOwnerName();
  }

  // Future<void> _fetchOwnerName() async {
  //   final job = widget.bookmark.job;
  //   if (job.agentId.isEmpty) return;
  //   final res = await UserHelper.fetchUserById(job.);
  //   if (mounted && res.success && res.data != null) {
  //     setState(() => _ownerName = res.data!.username);
  //   }
  // }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_showingBack) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _showingBack = !_showingBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final angle = _anim.value * pi;
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(showBack ? angle - pi : angle),
            child: showBack ? _buildBack(context) : _buildFront(context),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final job = widget.bookmark.job;
    return LayoutBuilder(
      builder: (_, constraints) {
        final cw = constraints.maxWidth;
        final ch = constraints.maxHeight;
        double cfx(double v) => cw * v / 609.0;
        double cfy(double v) => ch * v / 1222.0;

        return Container(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, error) => Container(
                        color: kThemeColor.withValues(alpha: 0.06),
                        child: const Icon(
                          Icons.business_rounded,
                          color: kThemeColor,
                          size: 48,
                        ),
                      ),
                      memCacheWidth: widget.imageCacheWidth,
                    ),
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
                    Positioned(
                      right: 10.w,
                      top: 10.h,
                      child: SizedBox(
                        width: 82.w,
                        height: 50.h,
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              'assets/userbox.svg',
                              width: 82.w,
                              height: 50.h,
                              fit: BoxFit.fill,
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 6.h,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20.w,
                                      height: 20.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _ownerName != null
                                            ? _initials(_ownerName!)
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 7.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Created by',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 6.5.sp,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontWeight: FontWeight.w400,
                                              height: 1.0,
                                            ),
                                          ),
                                          SizedBox(height: 1.h),
                                          if (_ownerName != null)
                                            Text(
                                              _ownerName!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 7.5.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                              ),
                                            )
                                          else
                                            Container(
                                              height: 7.h,
                                              width: 40.w,
                                              decoration: BoxDecoration(
                                                color: Colors.white24,
                                                borderRadius:
                                                    BorderRadius.circular(3.r),
                                              ),
                                            ),
                                        ],
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
                      if (job.company.isNotEmpty || job.domain.isNotEmpty) ...[
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
                            if (job.company.isNotEmpty && job.domain.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
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
                      if (job.description.isNotEmpty) ...[
                        Text(
                          job.description,
                          maxLines: widget.isExpanded ? null : 2,
                          overflow: widget.isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            color: const Color(0xFF444444),
                            height: 1.5,
                          ),
                        ),
                        if (!widget.isExpanded)
                          GestureDetector(
                            onTap: widget.onToggleExpanded,
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
                            if (job.skills.length > 4) ...[
                              const Spacer(),
                              Text(
                                'Tap card to see more',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.sp,
                                  color: const Color(0xFF999999),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8.h),
                        SkillChipsWrap(skills: job.skills.take(4).toList()),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBack(BuildContext context) {
    final job = widget.bookmark.job;
    return LayoutBuilder(
      builder: (_, constraints) {
        final cw = constraints.maxWidth;
        double cfx(double v) => cw * v / 609.0;

        return Container(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: cfx(44),
                color: kThemeColor,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      (job.opportunityType.isNotEmpty
                              ? job.opportunityType
                              : job.domain)
                          .toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(cfx(14), 16.h, cfx(14), 80.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (job.requirements.isNotEmpty) ...[
                        Text(
                          'Requirements',
                          style: GoogleFonts.dmSans(
                            fontSize: 13.sp,
                            color: kThemeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...job.requirements.map(
                          (req) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Icon(
                                    Icons.radio_button_unchecked,
                                    size: 12.w,
                                    color: kThemeColor,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF333333),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        SizedBox(height: 14.h),
                      ],

                      _buildInfoBoxGrid(job),

                      if (job.skills.length > 4) ...[
                        SizedBox(height: 14.h),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        SizedBox(height: 12.h),
                        Text(
                          'More Skills',
                          style: GoogleFonts.dmSans(
                            fontSize: 13.sp,
                            color: kThemeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SkillChipsWrap(skills: job.skills.skip(4).toList()),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBoxGrid(dynamic job) {
    final items = <_InfoItem>[];
    if (job.period.isNotEmpty) {
      items.add(
        _InfoItem(
          label: 'Duration',
          value: job.period,
          icon: Icons.calendar_today_outlined,
        ),
      );
    }
    if (job.salary.isNotEmpty) {
      items.add(
        _InfoItem(
          label: 'Stipend',
          value: job.salary,
          icon: Icons.attach_money_rounded,
        ),
      );
    }
    if (job.experienceLevel.isNotEmpty) {
      items.add(
        _InfoItem(
          label: 'Experience',
          value: job.experienceLevel,
          icon: Icons.work_outline_rounded,
        ),
      );
    }
    if (job.fieldDegree.isNotEmpty) {
      items.add(
        _InfoItem(
          label: 'Field/Degree',
          value: job.fieldDegree,
          icon: Icons.school_outlined,
        ),
      );
    }
    if (job.languagePreference.isNotEmpty) {
      items.add(
        _InfoItem(
          label: 'Language Preferred',
          value: job.languagePreference,
          icon: Icons.language_outlined,
        ),
      );
    }
    if (job.contract.isNotEmpty) {
      items.add(
        _InfoItem(
          label: 'Additional Info',
          value: job.contract,
          icon: Icons.info_outline_rounded,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _infoBox(left)),
            SizedBox(width: 8.w),
            Expanded(
              child: right != null ? _infoBox(right) : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < items.length) rows.add(SizedBox(height: 8.h));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _infoBox(_InfoItem item) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEDE3DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: kThemeColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(item.icon, size: 14.w, color: kThemeColor),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.sp,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.sp,
                    color: const Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}
