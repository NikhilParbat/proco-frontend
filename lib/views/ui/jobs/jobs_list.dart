import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/loader.dart';
import 'package:proco/views/ui/jobs/widgets/job_tile.dart';
import 'package:provider/provider.dart';

class JobListPage extends StatelessWidget {
  const JobListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.h),
        child: CustomAppBar(
          text: 'Queries',
          child: GestureDetector(
            onTap: Get.back,
            child: const Icon(CupertinoIcons.arrow_left),
          ),
        ),
      ),
      body: Consumer<JobsNotifier>(
        builder: (context, joblist, child) {
          if (joblist.isLoadingJobList) {
            return const Center(child: CircularProgressIndicator());
          }

          if (joblist.jobList.isEmpty) {
            return const SearchLoading(text: 'No Opportunities to display');
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              itemCount: joblist.jobList.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return VerticalTileWidget(job: joblist.jobList[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
