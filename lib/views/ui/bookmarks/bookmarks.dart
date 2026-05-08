import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
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

                    final selected = index == _selectedIndex;

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
                          color: selected ? kThemeColor : Colors.white,

                          borderRadius: BorderRadius.circular(16.r),

                          border: Border.all(
                            color: selected
                                ? kThemeColor
                                : kThemeColor.withOpacity(0.08),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),

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

                              color: selected ? Colors.white : kThemeColor,
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

                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
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

                    return Padding(
                      padding: EdgeInsets.only(bottom: 14.h),

                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookmarkCardSwiper(
                                bookmarks: [bookmark],
                                bookmarkNotifier: bookMarkNotifier,
                              ),
                            ),
                          );
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius: BorderRadius.circular(22.r),

                            border: Border.all(
                              color: kThemeColor.withOpacity(0.06),
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),

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
                                        )
                                      : Container(
                                          color: kThemeColor.withOpacity(0.08),

                                          child: Icon(
                                            Icons.work_outline_rounded,

                                            color: kThemeColor,

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

                                      // ── Bottom Row ──────
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,

                                            size: 15.sp,

                                            color: kThemeColor,
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

                                      // ── Type Chip ───────
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 5.h,
                                        ),

                                        decoration: BoxDecoration(
                                          color: kThemeColor.withOpacity(0.08),

                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                        ),

                                        child: Text(
                                          job.opportunityType,

                                          style: TextStyle(
                                            fontFamily: kFontDMSans,

                                            fontSize: 10.5.sp,

                                            fontWeight: FontWeight.w700,

                                            color: kThemeColor,
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
                                  Icons.arrow_forward_ios_rounded,
                                  size: 15.sp,
                                  color: Colors.black26,
                                ),
                              ),
                            ],
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
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 92.w,
              height: 92.w,

              decoration: BoxDecoration(
                color: kThemeColor.withOpacity(0.10),

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 42.w,
                color: kThemeColor,
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'No saved opportunities',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              'Swipe up on an opportunity card to save it and access it later here.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
