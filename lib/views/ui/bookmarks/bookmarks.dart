import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/drawer/drawer_widget.dart';
import 'package:proco/views/ui/bookmarks/bookmark_card_swiper.dart';
import 'package:provider/provider.dart';

class BookMarkPage extends StatefulWidget {
  const BookMarkPage({super.key});

  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  static const Color _teal = Color(0xFF08979F);
  static const Color _navy = Color(0xFF040326);

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
      backgroundColor: _navy,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.065.sh),
        child: CustomAppBar(
          text: 'Saved Jobs',
          child: Padding(
            padding: EdgeInsets.only(left: 0.010.sh),
            child: const DrawerWidget(),
          ),
        ),
      ),
      body: Consumer<BookMarkNotifier>(
        builder: (context, bookMarkNotifier, child) {
          return FutureBuilder<List<AllBookmark>>(
            future: bookMarkNotifier.bookmarks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _teal),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error ${snapshot.error}',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmpty();
              }

              final bookmarks = snapshot.data!;

              return BookmarkCardSwiper(
                bookmarks: bookmarks,
                bookmarkNotifier: bookMarkNotifier,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_outline_rounded,
            size: 64,
            color: _teal.withValues(alpha: 0.25),
          ),
          SizedBox(height: 16.h),
          Text(
            'No saved jobs',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Swipe up on a job card to save it',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
