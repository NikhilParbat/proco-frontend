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
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);
  static const Color _bg = Color(0xFFF4F6FA);

  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool _isFilterActive(GetFilterRes f) {
    return f.selectedOptions.isNotEmpty ||
        f.skills.isNotEmpty ||
        f.internship || f.research || f.freelance || f.competition || f.collaborate ||
        f.selectedLocationOption.isNotEmpty ||
        f.sortByTime ||
        f.postedWithin.isNotEmpty;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (mounted) setState(() => _currentUserId = userId);
  }

  Future<void> _refreshAfterFilter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FilterPage()),
    );
    if (mounted) {
      final bookmarkedIds =
          Provider.of<BookMarkNotifier>(context, listen: false).jobs;
      Provider.of<JobsNotifier>(context, listen: false)
          .preloadJobs(_currentUserId, bookmarkedIds: bookmarkedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.065.sh),
        child: CustomAppBar(
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 0.01.sh),
              child: Consumer<FilterNotifier>(
                builder: (context, filterNotifier, _) {
                  final hasFilter = filterNotifier.activeFilter != null &&
                      _isFilterActive(filterNotifier.activeFilter!);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(FontAwesome.filter,
                            color: hasFilter ? _teal : _teal),
                        onPressed: _refreshAfterFilter,
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
          // ── Active filter chips ──────────────────────────────────────────
          Consumer<FilterNotifier>(
            builder: (context, filterNotifier, _) {
              final f = filterNotifier.activeFilter;
              if (f == null || !_isFilterActive(f)) return const SizedBox.shrink();
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
                color: _navy,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, color: _teal, size: 16),
                      SizedBox(width: 6.w),
                      ...chips.map((chip) => Container(
                            margin: EdgeInsets.only(right: 6.w),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _teal.withValues(alpha: 0.5)),
                            ),
                            child: Text(chip,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          )),
                      GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId') ?? '';
                          if (context.mounted) {
                            await context.read<FilterNotifier>().clearFilter(userId);
                            if (context.mounted) {
                              context.read<JobsNotifier>().preloadJobs(userId);
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf55631).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFf55631).withValues(alpha: 0.5)),
                          ),
                          child: const Text('Clear', style: TextStyle(color: Color(0xFFf55631), fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // ── Job cards ────────────────────────────────────────────────────
          Expanded(
            child: Consumer2<JobsNotifier, BookMarkNotifier>(
              builder: (context, jobNotifier, bookmarkNotifier, _) {
                final bookmarkedIds = bookmarkNotifier.jobs;
                final jobs = jobNotifier.getDisplayableJobs(
                  _currentUserId,
                  bookmarkedIds: bookmarkedIds,
                );

                if (jobNotifier.isLoadingJobs && jobs.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: _teal));
                }

                if (jobs.isEmpty) return _buildEmptyState();

                return JobCardSwiper(
                  jobs: jobs,
                  currentUserId: _currentUserId,
                  jobNotifier: jobNotifier,
                  bookmarkNotifier: bookmarkNotifier,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_rounded, size: 64, color: _teal.withValues(alpha:0.4)),
          SizedBox(height: 16.h),
          Text(
            'No jobs available',
            style: TextStyle(
              fontSize: 18.sp,
              color: _navy,
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
