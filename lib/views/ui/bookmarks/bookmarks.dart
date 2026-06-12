import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/views/common/empty_state_widget.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/lagoon_snackbar.dart';
import 'package:proco/views/common/wave_loader.dart';
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
            return const Center(child: WaveLoader());
          }

          if (bookMarkNotifier.bookmarks.isEmpty) {
            return _buildEmpty();
          }

          final bookmarks = bookMarkNotifier.bookmarks;

          if (_selectedIndex >= bookmarks.length) {
            _selectedIndex = 0;
          }

          // Replace everything inside your Consumer<BookMarkNotifier> success state with this

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved Opportunities',
                        style: GoogleFonts.montserrat(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        '${bookMarkNotifier.bookmarks.length} opportunities saved for later',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.sp,
                          color: Colors.black54,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      _buildStatsCard(bookMarkNotifier.bookmarks),

                      SizedBox(height: 20.h),

                      // _buildFeaturedCard(
                      //   context,
                      //   bookMarkNotifier.bookmarks.first,
                      //   bookMarkNotifier,
                      // ),
                      // SizedBox(height: 28.h),

                      // Text(
                      //   'All Saved',
                      //   style: TextStyle(
                      //     fontFamily: kFontMontserrat,
                      //     fontSize: 18.sp,
                      //     fontWeight: FontWeight.w700,
                      //     color: Colors.black87,
                      //   ),
                      // ),
                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final bookmark = bookMarkNotifier.bookmarks[index];
                    final job = bookmark.job;
                    final active = job.isActive;

                    return GestureDetector(
                      onTap: () {
                        if (!active) {
                          LagoonSnackbar.show(
                            title: 'Temporarily Unavailable',
                            message: 'This opportunity is currently paused.',
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: kBackgroundColor,
                              appBar: AppBar(
                                backgroundColor: kBackgroundColor,
                                elevation: 0,
                                iconTheme: const IconThemeData(
                                  color: kThemeColor,
                                ),
                                title: Text(
                                  job.title,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                    color: kThemeColor,
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
                      child: Container(
                        margin: EdgeInsets.only(bottom: 14.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: active
                                ? kThemeColor.withValues(alpha: 0.08)
                                : Colors.grey.shade300,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: active ? 1 : 0.55,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 58.w,
                                    height: 58.w,
                                    decoration: BoxDecoration(
                                      color: kThemeColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: job.hasImage
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            child: Image.network(
                                              job.imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Icon(
                                            Icons.work_outline_rounded,
                                            color: kThemeColor,
                                            size: 28.sp,
                                          ),
                                  ),

                                  SizedBox(width: 14.w),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        SizedBox(height: 4.h),

                                        Text(
                                          job.companyText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16.sp,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),

                              SizedBox(height: 14.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: _infoChip(
                                      Icons.location_on_outlined,
                                      job.location,
                                    ),
                                  ),

                                  SizedBox(width: 8.w),

                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? kThemeColor.withValues(alpha: 0.08)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                    child: Text(
                                      active ? job.opportunityType : 'PAUSED',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? kThemeColor
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: bookMarkNotifier.bookmarks.length),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
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
      subtitle:
          'Swipe up on an opportunity card to save it and access it later here.',
    );
  }
}

// Widget _buildFeaturedCard(
//   BuildContext context,
//   dynamic bookmark,
//   BookMarkNotifier notifier,
// ) {
//   final job = bookmark.job;

//   return GestureDetector(
//     onTap: () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => Scaffold(
//             backgroundColor: kBackgroundColor,
//             appBar: AppBar(
//               backgroundColor: kThemeColor,
//               title: Text(job.title),
//             ),
//             body: SafeArea(
//               child: BookmarkCardSwiper(
//                 bookmarks: [bookmark],
//                 bookmarkNotifier: notifier,
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//     child: Container(
//       height: 220.h,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(26.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.12),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(26.r),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             job.hasImage
//                 ? Image.network(job.imageUrl, fit: BoxFit.cover)
//                 : Container(color: kThemeColor),

//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                   colors: [
//                     Colors.black.withValues(alpha: 0.85),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),

//             Positioned(
//               left: 18.w,
//               right: 18.w,
//               bottom: 18.h,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'FEATURED',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 11.sp,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),

//                   SizedBox(height: 6.h),

//                   Text(
//                     job.title,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontFamily: kFontMontserrat,
//                       color: Colors.white,
//                       fontSize: 22.sp,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),

//                   SizedBox(height: 6.h),

//                   Text(
//                     job.companyText,
//                     style: TextStyle(
//                       fontFamily: kFontDMSans,
//                       color: Colors.white70,
//                       fontSize: 13.sp,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

Widget _buildStatsCard(List bookmarks) {
  final activeCount = bookmarks.where((e) => e.job.isActive).length;

  final pausedCount = bookmarks.length - activeCount;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem(bookmarks.length.toString(), 'Saved'),
        _statItem(activeCount.toString(), 'Active'),
        _statItem(pausedCount.toString(), 'Paused'),
      ],
    ),
  );
}

Widget _statItem(String value, String label) {
  return Column(
    children: [
      Text(
        value,
        style: GoogleFonts.dmSans(
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: kThemeColor,
        ),
      ),
      SizedBox(height: 4.h),
      Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 12.sp, color: Colors.black54),
      ),
    ],
  );
}

Widget _infoChip(IconData icon, String text) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: kThemeColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(100.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: kThemeColor),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 11.sp,
              color: kThemeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
