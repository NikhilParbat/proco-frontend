import 'package:flutter/material.dart';
import 'package:proco/controllers/jobs_provider.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/loader.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/ui/jobs/add_job.dart';
import 'package:proco/views/ui/jobs/widgets/job_tile.dart';
import 'package:provider/provider.dart';

class JobListPage extends StatelessWidget {
  const JobListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddJobPage()),
        ),
        backgroundColor: kThemeColor,
        child: const Icon(Icons.add, color: Colors.white),
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
