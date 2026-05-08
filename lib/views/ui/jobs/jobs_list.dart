import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/loader.dart';
import 'package:proco/views/ui/jobs/add_job.dart';
import 'package:proco/views/ui/jobs/matched_users.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({super.key});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  late List<JobsResponse> jobs = [];
  late List<JobsResponse> filteredJobs = [];

  String selectedStatus = 'all';

  final List<Map<String, String>> filters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'hiring', 'label': 'Hiring'},
    {'value': 'closed', 'label': 'Closed'},
  ];

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              color: kThemeColor.withOpacity(0.10),
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
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontFamily: kFontDMSans,
            ),
          ),

          SizedBox(height: 6.h),

          Text(
            'Tap the + button to create your first opportunity',
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

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
      loadJobs();
    });
  }

  void filterJobs() {
    if (selectedStatus == 'all') {
      filteredJobs = jobs;
    } else if (selectedStatus == 'hiring') {
      filteredJobs = jobs.where((job) => job.hiring).toList();
    } else {
      filteredJobs = jobs.where((job) => !job.hiring).toList();
    }
  }

  void loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty || !mounted) return;

    final notifier = context.read<JobsNotifier>();

    await notifier.loadCachedUserJobs(userId);

    if (mounted) {
      notifier.getUserJobs(userId);
    }
  }

  Future<void> setCurrentJobId(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentJobId', jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
      backgroundColor: Colors.white,

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddJobPage()),
        ).then((_) => loadJobs()),
        backgroundColor: kThemeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Consumer<JobsNotifier>(
        builder: (context, jobsNotifier, child) {
          if (jobsNotifier.isLoadingUserJobs) {
            return const Center(
              child: CircularProgressIndicator(color: kThemeColor),
            );
          }

          if (jobsNotifier.userJobs.isEmpty) {
            return _buildEmptyState();
          }

          jobs = jobsNotifier.userJobs;
          filterJobs();

          return Column(
            children: [
              /// FILTERS
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Text(
                      '${filteredJobs.length} opportunities',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey,
                        fontFamily: kFontDMSans,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      children: filters.map((f) {
                        final isSelected = selectedStatus == f['value'];

                        return Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedStatus = f['value']!;
                                filterJobs();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 7.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? kThemeColor : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? kThemeColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                f['label']!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: kFontDMSans,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              /// JOB LIST
              Expanded(
                child: filteredJobs.isEmpty
                    ? Center(
                        child: Text(
                          'No opportunities match this filter',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                            fontFamily: kFontDMSans,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, index) {
                          final job = filteredJobs[index];

                          return JobCard(
                            job: job,

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

                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddJobPage(job: job),
                                ),
                              ).then((_) => loadJobs());
                            },

                            onDelete: () {
                              Get.defaultDialog(
                                title: "Delete Opportunity",
                                middleText:
                                    "Are you sure you want to delete this opportunity?",
                                textConfirm: "Delete",
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.red,
                                onConfirm: () async {
                                  await context.read<JobsNotifier>().deleteJob(
                                    job.id,
                                  );

                                  Get.back();

                                  setState(() {
                                    filteredJobs.removeAt(index);
                                  });

                                  Get.snackbar(
                                    "Deleted",
                                    "Opportunity removed successfully",
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                },
                              );
                            },
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

class JobCard extends StatelessWidget {
  final JobsResponse job;
  final VoidCallback onViewMatches;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const JobCard({
    super.key,
    required this.job,
    required this.onViewMatches,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isHiring = job.hiring;

    return GestureDetector(
      onTap: onViewMatches,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF040326),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    job.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: kThemeColor.withOpacity(0.12),
                      child: const Icon(
                        Icons.business,
                        color: kThemeColor,
                        size: 36,
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHiring ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isHiring ? 'Hiring' : 'Closed',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: kFontDMSans,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kThemeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${job.matchedUsers.length}',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: kFontDMSans,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: kFontDMSans,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHiring ? 'Hiring' : 'Closed',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isHiring
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                          fontFamily: kFontDMSans,
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onEdit,
                            child: const Icon(
                              Icons.edit_outlined,
                              color: kThemeColor,
                              size: 18,
                            ),
                          ),

                          SizedBox(width: 10.w),

                          GestureDetector(
                            onTap: onDelete,
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
