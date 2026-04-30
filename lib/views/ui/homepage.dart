import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/filter_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/drawer/drawer_widget.dart';
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
  static const Color _teal = Color(0xFF08979F);
  static const Color _bg = Color(0xFFF4F6FA);

  // ✅ Memoize filter check
  bool _isFilterActive(GetFilterRes f) {
    return f.selectedOptions.isNotEmpty ||
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
      );
    }
  }

  @override
  void initState() {
    super.initState();

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

    // // Step 2: Delay notifications (heavy)
    // Future.delayed(const Duration(seconds: 2), () {
    //   if (!mounted) return;

    //   Future.delayed(const Duration(seconds: 2), () async {
    //     if (!mounted) return;

    //     final prefs = await SharedPreferences.getInstance();
    //     final token = prefs.getString('token') ?? '';

    //     if (widget.userId.isNotEmpty && token.isNotEmpty) {
    //       NotificationHelper.initialize(widget.userId, token);
    //     }
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.065.sh),
        child: CustomAppBar(
          actions: [
            // ✅ Isolated filter button widget
            _FilterButton(
              onPressed: _refreshAfterFilter,
              isFilterActive: _isFilterActive,
            ),
            Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: IconButton(
                icon: const Icon(FontAwesome.bell, color: _teal, size: 18),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                ),
              ),
            ),
          ],
          child: Padding(
            padding: EdgeInsets.only(left: 0.010.sh),
            child: const DrawerWidget(),
          ),
        ),
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

// ✅ NEW: Isolated filter button to prevent unnecessary rebuilds
class _FilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool Function(GetFilterRes) isFilterActive;

  const _FilterButton({required this.onPressed, required this.isFilterActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 0.01.sh),
      child: Consumer<FilterNotifier>(
        builder: (context, filterNotifier, _) {
          final hasFilter =
              filterNotifier.activeFilter != null &&
              isFilterActive(filterNotifier.activeFilter!);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(FontAwesome.filter, color: Color(0xFF08979F)),
                onPressed: onPressed,
              ),
              if (hasFilter)
                Positioned(
                  top: 8,
                  right: 8,
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
      ),
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
          color: const Color(0xFF040326),
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
                      context.read<JobsNotifier>().preloadJobs(userId);
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
              color: const Color(0xFF040326),
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
