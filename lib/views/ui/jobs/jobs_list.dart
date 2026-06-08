import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/controllers/zoom_provider.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/services/config.dart' as app_config;
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/ui/jobs/add_job.dart';
import 'package:proco/views/ui/jobs/matched_users.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobListPage extends StatefulWidget {
  /// Index of this page inside [MainScreen]'s bottom-nav [IndexedStack].
  /// When set, the page reloads its jobs every time the tab becomes active
  /// again (the IndexedStack keeps the page alive, so initState only runs
  /// once). Leave null when pushed as a standalone route (e.g. from the
  /// drawer), where initState already re-runs on each push.
  final int? tabIndex;

  const JobListPage({super.key, this.tabIndex});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<JobsResponse> jobs = [];

  ZoomNotifier? _zoom;
  int _lastTabIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    Future.delayed(const Duration(milliseconds: 500), loadJobs);

    // Refresh applicant/match counts whenever the user returns to this tab.
    if (widget.tabIndex != null) {
      _zoom = context.read<ZoomNotifier>();
      _lastTabIndex = _zoom!.currentIndex;
      _zoom!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    final current = _zoom?.currentIndex ?? -1;
    // Only reload when this tab just became active (entered from another tab).
    if (current == widget.tabIndex && _lastTabIndex != widget.tabIndex) {
      loadJobs();
    }
    _lastTabIndex = current;
  }

  @override
  void dispose() {
    _zoom?.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  List<JobsResponse> get _filteredJobs {
    if (_tabController.index == 0) {
      return jobs.where((j) => j.isActive).toList();
    } else {
      return jobs.where((j) => !j.isActive).toList();
    }
  }

  void loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty || !mounted) return;
    final notifier = context.read<JobsNotifier>();
    await notifier.loadCachedUserJobs(userId);
    if (mounted) notifier.getUserJobs(userId);
  }

  Future<void> setCurrentJobId(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentJobId', jobId);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) {
      final y = (diff.inDays / 365).floor();
      return '$y year${y > 1 ? 's' : ''} ago';
    }
    if (diff.inDays >= 30) {
      final m = (diff.inDays / 30).floor();
      return '$m month${m > 1 ? 's' : ''} ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  Widget _buildEmptyState() {
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
            'No opportunities yet',
            style: GoogleFonts.dmSans(
              fontSize: 18.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Tap the + button to create your first opportunity',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13.sp,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
      backgroundColor: kBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddJobPage()),
        ).then((_) => loadJobs()),
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<JobsNotifier>(
        builder: (context, jobsNotifier, child) {
          if (jobsNotifier.isLoadingUserJobs && jobsNotifier.userJobs.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kThemeColor),
            );
          }

          jobs = jobsNotifier.userJobs;

          if (jobs.isEmpty) return _buildEmptyState();

          final filteredJobs = _filteredJobs;
          final totalApplicants = jobs.fold<int>(
            0,
            (sum, j) => sum + j.applicantsCount,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Tabs: Active / Closed
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorWeight: 2.5,
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Closed'),
                  ],
                ),
              ),

              /// Stat boxes
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: Row(
                  children: [
                    _StatBox(label: 'Total\nQueries', value: '${jobs.length}'),
                    SizedBox(width: 12.w),
                    _StatBox(
                      label: 'Total\nApplicants',
                      value: '$totalApplicants',
                    ),
                  ],
                ),
              ),

              /// Section header
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
                child: Text(
                  'All Opportunities',
                  style: GoogleFonts.montserrat(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              /// Opportunity list
              Expanded(
                child: filteredJobs.isEmpty
                    ? Center(
                        child: Text(
                          'No opportunities here',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, index) {
                          final job = filteredJobs[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 14.h),
                            child: JobCard(
                              job: job,
                              timeAgo: _timeAgo(job.createdAt),
                              onViewMatches: () async {
                                await setCurrentJobId(job.id);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MatchedUsers(),
                                    ),
                                  );
                                }
                              },
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddJobPage(job: job),
                                ),
                              ).then((_) => loadJobs()),
                              onDelete: () {
                                final notifier = context.read<JobsNotifier>();
                                Get.defaultDialog(
                                  title: "Delete Opportunity",
                                  middleText:
                                      "Are you sure you want to delete this opportunity? This permanently removes it for everyone, including users who bookmarked it. This cannot be undone.",
                                  textConfirm: "Yes, delete",
                                  textCancel: "No",
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.red,
                                  onCancel: () {},
                                  onConfirm: () async {
                                    Get.back();
                                    final ok = await notifier.deleteJob(job.id);
                                    loadJobs();
                                    if (ok) {
                                      Get.snackbar(
                                        "Deleted",
                                        "Opportunity removed successfully",
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                                );
                              },
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
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: kDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: Colors.grey,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final JobsResponse job;
  final VoidCallback onViewMatches;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String timeAgo;

  const JobCard({
    super.key,
    required this.job,
    required this.onViewMatches,
    required this.onDelete,
    required this.onEdit,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewMatches,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header: thumbnail + title + edit icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: 46.w,
                    height: 46.w,
                    child: job.imageUrl.isNotEmpty
                        ? Image.network(
                            job.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, stack) => _placeholderIcon(),
                          )
                        : _placeholderIcon(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: kDark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              '${job.location} • $timeAgo',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.black,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'share') {
                      _showShareSheet(context);
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Edit',
                            style: GoogleFonts.dmSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Share',
                            style: GoogleFonts.dmSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Delete',
                            style: GoogleFonts.dmSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 14.h),

            /// Stat boxes: APPLICANTS | MATCHES
            Row(
              children: [
                Expanded(
                  child: _CardStatBox(
                    label: 'APPLICANTS',
                    value: '${job.applicantsCount}',
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _CardStatBox(
                    label: 'MATCHES',
                    value: '${job.matchesCount}',
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            /// Review Applicants button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewMatches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kThemeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Review Applicants',
                  style: GoogleFonts.dmSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final link = app_config.Config.opportunityShareUrl(job.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
                  child: Text(
                    'Share opportunity',
                    style: GoogleFonts.dmSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: kDark,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.black87),
                  title: Text(
                    'Copy link',
                    style: GoogleFonts.dmSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    Get.snackbar(
                      'Link copied',
                      'Opportunity link copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: kThemeColor,
                      colorText: Colors.white,
                      margin: EdgeInsets.all(12.w),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.business, color: Colors.grey, size: 22),
    );
  }
}

class _CardStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _CardStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: kDark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10.sp,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
