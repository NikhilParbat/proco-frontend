import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/controllers/bookmark_provider.dart';
import 'package:proco/controllers/jobs_provider.dart';
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
      Provider.of<JobsNotifier>(
        context,
        listen: false,
      ).preloadJobs(_currentUserId);
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
              child: IconButton(
                icon: const Icon(FontAwesome.filter, color: _teal),
                onPressed: _refreshAfterFilter,
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
      body: Consumer<JobsNotifier>(
        builder: (context, jobNotifier, _) {
          final jobs = jobNotifier.getDisplayableJobs(_currentUserId);

          if (jobNotifier.isLoadingJobs && jobs.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: _teal));
          }

          if (jobs.isEmpty) return _buildEmptyState();

          return JobCardSwiper(
            jobs: jobs,
            currentUserId: _currentUserId,
            jobNotifier: jobNotifier,
            bookmarkNotifier: Provider.of<BookMarkNotifier>(
              context,
              listen: false,
            ),
          );
        },
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
