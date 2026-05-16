import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/views/common/empty_state_widget.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/ui/bookmarks/bookmark_card_swiper.dart';
import 'package:provider/provider.dart';

class BookMarkPage extends StatefulWidget {
  const BookMarkPage({super.key});

  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookMarkNotifier>().getBookMarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),

      body: Consumer<BookMarkNotifier>(
        builder: (context, bookMarkNotifier, child) {
          if (bookMarkNotifier.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: kThemeColor,
                strokeWidth: 2.6,
              ),
            );
          }

          if (bookMarkNotifier.bookmarks.isEmpty) {
            return _buildEmpty();
          }

          final bookmarks = bookMarkNotifier.bookmarks;

          if (_selectedIndex >= bookmarks.length) {
            _selectedIndex = 0;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // ── Horizontal Bookmark Bars ─────────────────
              SizedBox(
                height: 52.h,

                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),

                  scrollDirection: Axis.horizontal,

                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    final active = bookmark.job.isActive;
                    final selected = index == _selectedIndex;

                    final chipColor = active
                        ? (selected ? kThemeColor : Colors.white)
                        : (selected
                            ? Colors.grey.shade400
                            : Colors.grey.shade100);
                    final chipBorder = active
                        ? (selected
                            ? kThemeColor
                            : kThemeColor.withValues(alpha: 0.08))
                        : Colors.grey.shade300;
                    final iconColor = active
                        ? (selected ? Colors.white : kThemeColor)
                        : Colors.grey.shade400;
                    final textColor = active
                        ? (selected ? Colors.white : Colors.black87)
                        : Colors.grey.shade400;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),

                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),

                        decoration: BoxDecoration(
                          color: chipColor,

                          borderRadius: BorderRadius.circular(16.r),

                          border: Border.all(color: chipBorder),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),

                              blurRadius: 10,

                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.bookmark_outline_rounded,
                              size: 16.sp,
                              color: iconColor,
                            ),

                            SizedBox(width: 8.w),

                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 130.w),

                              child: Text(
                                bookmark.job.title,

                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  fontFamily: kFontDMSans,

                                  fontSize: 13.sp,

                                  fontWeight: FontWeight.w700,

                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },

                  separatorBuilder: (_, __) => SizedBox(width: 10.w),

                  itemCount: bookmarks.length,
                ),
              ),

              SizedBox(height: 18.h),

              // ── Selected Card Swiper ───────────────────
              // ── Bookmark Tiles ────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 24.h),

                  itemCount: bookmarks.length,

                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    final job = bookmark.job;
                    final active = job.isActive;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),

                      child: GestureDetector(
                        onTap: () {
                          if (!active) {
                            Get.snackbar(
                              'Temporarily Unavailable',
                              'This opportunity is currently paused. Check back later.',
                              backgroundColor: Colors.grey.shade700,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              borderRadius: 12,
                              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                              duration: const Duration(seconds: 3),
                              icon: const Icon(Icons.pause_circle_outline,
                                  color: Colors.white),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: kBackgroundColor,

                                appBar: AppBar(
                                  backgroundColor: kThemeColor,
                                  elevation: 0,

                                  iconTheme: const IconThemeData(
                                    color: Colors.white,
                                  ),

                                  title: Text(
                                    bookmark.job.title,
                                    style: TextStyle(
                                      fontFamily: kFontMontserrat,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                body: SafeArea(
                                  child: BookmarkCardSwiper(
                                    bookmarks: [bookmark],
                                    bookmarkNotifier: bookMarkNotifier,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },

                        child: Opacity(
                          opacity: active ? 1.0 : 0.55,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(22.r),

                              border: Border.all(
                                color: active
                                    ? kThemeColor.withValues(alpha: 0.06)
                                    : Colors.grey.shade300,
                                width: active ? 1.0 : 1.5,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),

                            child: Row(
                              children: [
                                // ── Image ────────────────────
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(22.r),
                                    bottomLeft: Radius.circular(22.r),
                                  ),

                                  child: SizedBox(
                                    width: 105.w,
                                    height: 96.h,

                                    child: job.hasImage
                                        ? Image.network(
                                            job.imageUrl,
                                            fit: BoxFit.cover,
                                            color: active
                                                ? null
                                                : Colors.grey,
                                            colorBlendMode: active
                                                ? null
                                                : BlendMode.saturation,
                                          )
                                        : Container(
                                            color: active
                                                ? kThemeColor
                                                    .withValues(alpha: 0.08)
                                                : Colors.grey.shade100,

                                            child: Icon(
                                              Icons.work_outline_rounded,
                                              color: active
                                                  ? kThemeColor
                                                  : Colors.grey.shade400,
                                              size: 34.sp,
                                            ),
                                          ),
                                  ),
                                ),

                                // ── Content ──────────────────
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 12.h,
                                    ),

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        // ── Title ───────────
                                        Text(
                                          job.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: kFontDMSans,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        SizedBox(height: 5.h),

                                        // ── Company ─────────
                                        Text(
                                          job.companyText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: kFontDMSans,
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),

                                        SizedBox(height: 9.h),

                                        // ── Location ──────
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 15.sp,
                                              color: active
                                                  ? kThemeColor
                                                  : Colors.grey.shade400,
                                            ),
                                            SizedBox(width: 4.w),
                                            Expanded(
                                              child: Text(
                                                job.location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: kFontDMSans,
                                                  fontSize: 11.5.sp,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 10.h),

                                        // ── Type Chip / Paused badge ──
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? kThemeColor
                                                    .withValues(alpha: 0.08)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(14.r),
                                          ),
                                          child: Text(
                                            active
                                                ? job.opportunityType
                                                : 'PAUSED',
                                            style: TextStyle(
                                              fontFamily: kFontDMSans,
                                              fontSize: 10.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: active
                                                  ? kThemeColor
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Arrow ───────────────────
                                Padding(
                                  padding: EdgeInsets.only(right: 14.w),
                                  child: Icon(
                                    active
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.pause_circle_outline_rounded,
                                    size: 15.sp,
                                    color: active
                                        ? Colors.black26
                                        : Colors.grey.shade400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const EmptyStateWidget(
      icon: Icons.bookmark_outline_rounded,
      title: 'No saved opportunities',
      subtitle: 'Swipe up on an opportunity card to save it and access it later here.',
    );
  }
}
