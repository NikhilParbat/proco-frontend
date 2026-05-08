import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/views/common/exports.dart'; // Ensure kBackgroundColor is imported here
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
      // UPDATED: Now uses your uniform background variable
      backgroundColor: kBackgroundColor,
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
      body: Consumer<BookMarkNotifier>(
        builder: (context, bookMarkNotifier, child) {
          if (bookMarkNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator(color: _teal));
          }

          if (bookMarkNotifier.bookmarks.isEmpty) {
            return _buildEmpty();
          }

          return BookmarkCardSwiper(
            bookmarks: bookMarkNotifier.bookmarks,
            bookmarkNotifier: bookMarkNotifier,
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
          Container(
            width: 90.w,
            height: 90.w,
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

          SizedBox(height: 18.h),

          Text(
            'No saved opportunities',
            style: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 6.h),

          Text(
            'Swipe up on an opportunity card to save it',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 13.sp,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
