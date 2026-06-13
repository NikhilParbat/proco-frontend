import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/constants/app_text_styles.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/filter_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/helpers/notification_helper.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/wave_loader.dart';
import 'package:proco/views/ui/filters/filter_page.dart';
import 'package:proco/views/ui/jobs/job_card_swiper.dart';
import 'package:proco/views/ui/notification/notification_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String userId; // ✅ Passed from MainScreen

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // static const Color _navy = Color(0xFF040326);
  static const Color _bg = Color(0xFFF4F6FA);

  bool _hasNewNotification = NotificationHelper.hasUnread;

  void _onNotificationUpdate() {
    if (mounted) {
      setState(() {
        _hasNewNotification = NotificationHelper.hasUnread;
      });
    }
  }

  // ✅ Memoize filter check
  bool _isFilterActive(GetFilterRes f) {
    return f.skills.isNotEmpty ||
        f.selectedDomains.isNotEmpty ||
        f.opportunityTypes.isNotEmpty ||
        f.selectedLocationOption.isNotEmpty ||
        f.distanceKm > 0 ||
        f.sortByTime ||
        f.postedWithin.isNotEmpty;
  }

  // ✅ Helper for clean, consistent Action Buttons with dots
  Widget _buildAppBarAction({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34.w,
        height: 34.w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(icon, size: size, color: Colors.black),
            ),

            if (showDot)
              Positioned(
                right: 2.w,
                top: 4.h,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: kSend,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAfterFilter() async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FilterPage()),
    );
    if (mounted && applied == true) {
      final bookmarkedIds = context.read<BookMarkNotifier>().jobs;
      context.read<JobsNotifier>().preloadJobs(
        widget.userId,
        bookmarkedIds: bookmarkedIds,
        forceRefresh: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    NotificationHelper.addListener(_onNotificationUpdate);

    // Load jobs and sync filter from backend right after the first frame —
    // no artificial delay (the preload is already cache-first + debounced).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bookmarkedIds = context.read<BookMarkNotifier>().jobs;

      context.read<JobsNotifier>().preloadJobs(
        widget.userId,
        bookmarkedIds: bookmarkedIds,
      );

      // Sync saved filter from backend so chip bar is accurate after login
      context.read<FilterNotifier>().loadFilterForUser(widget.userId);
    });
  }

  @override
  void dispose() {
    NotificationHelper.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: const LagoonDrawer(),
      appBar: LagoonAppBar(
        actions: [
          Builder(
            builder: (context) {
              final filterNotifier = context.watch<FilterNotifier>();
              final filterActive =
                  filterNotifier.activeFilter != null &&
                  _isFilterActive(filterNotifier.activeFilter!);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAppBarAction(
                    icon: CupertinoIcons.slider_horizontal_3,
                    size: 24.w,
                    onTap: _refreshAfterFilter,
                    showDot: filterActive,
                  ),
                ],
              );
            },
          ),

          _buildAppBarAction(
            icon: CupertinoIcons.bell,
            size: 22.w,
            onTap: () {
              // Opening the list counts as seeing the notifications, so clear
              // the unread state at the source. The listener recomputes the dot.
              NotificationHelper.markAllAsRead();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
            showDot: _hasNewNotification,
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: _JobsList(userId: widget.userId),
    );
  }
}

// ✅ NEW: Isolated jobs list
class _JobsList extends StatelessWidget {
  final String userId;

  const _JobsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<JobsNotifier, BookMarkNotifier>(
      builder: (context, jobNotifier, bookmarkNotifier, _) {
        final bookmarkedIds = bookmarkNotifier.jobs;
        final jobs = jobNotifier.getDisplayableJobs(
          userId,
          bookmarkedIds: bookmarkedIds,
        );

        if (jobNotifier.isLoadingJobs && jobs.isEmpty) {
          return const Center(child: WaveLoader());
        }

        if (jobs.isEmpty) return const _EmptyState();

        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: JobCardSwiper(
            jobs: jobs,
            currentUserId: userId,
            jobNotifier: jobNotifier,
            bookmarkNotifier: bookmarkNotifier,
          ),
        );
      },
    );
  }
}

// ✅ NEW: Isolated empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
              Icons.work_outline_rounded,
              size: 42.w,
              color: kThemeColor,
            ),
          ),

          SizedBox(height: 18.h),

          Text(
            'No opportunities available',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontFamily: kFontDMSans,
            ),
          ),

          SizedBox(height: 6.h),

          Text(
            'Check back later for new opportunities',
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
