import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/filter_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/helpers/notification_helper.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
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

  bool _hasNewNotification = NotificationHelper.notifications.isNotEmpty;

  void _onNotificationUpdate() {
    if (mounted) {
      setState(() {
        _hasNewNotification = NotificationHelper.notifications.isNotEmpty;
      });
    }
  }

  // ✅ Memoize filter check
  bool _isFilterActive(GetFilterRes f) {
    return f.selectedOptions.isNotEmpty ||
        f.customOptions.isNotEmpty ||
        f.skills.isNotEmpty ||
        f.internship ||
        f.research ||
        f.freelance ||
        f.competition ||
        f.collaborate ||
        f.selectedLocationOption.isNotEmpty ||
        f.sortByTime ||
        f.postedWithin.isNotEmpty;
  }

  // ✅ Helper for clean, consistent Action Buttons with dots
  Widget _buildAppBarAction({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    required bool showDot,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: size, color: Colors.black),
            if (showDot)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: kThemeColor,
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FilterPage()),
    );
    if (mounted) {
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

    // Step 1: Load jobs AFTER UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        final bookmarkedIds = context.read<BookMarkNotifier>().jobs;

        context.read<JobsNotifier>().preloadJobs(
          widget.userId,
          bookmarkedIds: bookmarkedIds,
        );
      });
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
          _buildAppBarAction(
            icon: CupertinoIcons.slider_horizontal_3,
            size: 27.w,
            onTap: _refreshAfterFilter,
            showDot:
                context.watch<FilterNotifier>().activeFilter != null &&
                _isFilterActive(context.watch<FilterNotifier>().activeFilter!),
          ),
          SizedBox(width: 2.w),
          _buildAppBarAction(
            icon: CupertinoIcons.bell,
            size: 24.w,
            onTap: () {
              setState(() => _hasNewNotification = false);
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
      body: Column(
        children: [
          // ✅ Isolated filter chips widget
          _FilterChipsBar(
            userId: widget.userId,
            isFilterActive: _isFilterActive,
          ),
          // ✅ Isolated job list widget
          Expanded(child: _JobsList(userId: widget.userId)),
        ],
      ),
    );
  }

}

// ✅ UPDATED: Filter button now uses standard Flutter Icon to match AppBar
class _FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool Function(GetFilterRes) isFilterActive;

  const _FilterButton({required this.onPressed, required this.isFilterActive});

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterNotifier>(
      builder: (context, filterNotifier, _) {
        final hasFilter =
            filterNotifier.activeFilter != null &&
            isFilterActive(filterNotifier.activeFilter!);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
              icon: Icon(Icons.tune, size: 24.w, color: Colors.black),
              onPressed: onPressed,
            ),
            if (hasFilter)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFf55631),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ✅ NEW: Isolated filter chips bar
class _FilterChipsBar extends StatelessWidget {
  final String userId;
  final bool Function(GetFilterRes) isFilterActive;

  const _FilterChipsBar({required this.userId, required this.isFilterActive});

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterNotifier>(
      builder: (context, filterNotifier, _) {
        final f = filterNotifier.activeFilter;
        if (f == null || !isFilterActive(f)) return const SizedBox.shrink();

        final chips = <String>[
          ...f.selectedOptions,
          ...f.customOptions,
          ...f.skills,
          if (f.internship) 'Internship',
          if (f.research) 'Research',
          if (f.freelance) 'Freelance',
          if (f.competition) 'Competition',
          if (f.collaborate) 'Collaborate',
          if (f.selectedLocationOption.isNotEmpty) f.selectedLocationOption,
          if (f.sortByTime) 'Latest first',
          if (f.postedWithin.isNotEmpty) f.postedWithin,
        ];

        return Container(
          color: Colors.black,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  color: Color(0xFF08979F),
                  size: 16,
                ),
                SizedBox(width: 6.w),
                ...chips.map(
                  (chip) => Container(
                    margin: EdgeInsets.only(right: 6.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF08979F).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF08979F).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await context.read<FilterNotifier>().clearFilter(userId);
                    if (context.mounted) {
                      context.read<JobsNotifier>().preloadJobs(
                        userId,
                        forceRefresh: true,
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf55631).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFf55631).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Color(0xFFf55631), fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF08979F)),
          );
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
          Icon(
            Icons.work_off_rounded,
            size: 64,
            color: const Color(0xFF08979F).withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            'No jobs available',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Check back later for new opportunities',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
