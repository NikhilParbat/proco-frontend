import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/services/helpers/jobs_helper.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/common/loader.dart';
import 'package:proco/views/ui/jobs/widgets/job_tile.dart';
import 'package:proco/views/ui/search/widgets/custom_field.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController search = TextEditingController();

  List<JobsResponse> _results = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _search() async {
    final query = search.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _results = [];
    });

    final response = await JobsHelper.searchJobs(query);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _results = response.data!;
      } else {
        _error = response.message;
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kOrange,
        iconTheme: IconThemeData(color: kLight),
        title: CustomField(
          hintText: 'Search for a job',
          controller: search,
          onEditingComplete: _search,
          suffixIcon: GestureDetector(
            onTap: _search,
            child: const Icon(AntDesign.search1),
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (search.text.isEmpty) {
      return const SearchLoading(text: 'Start Searching For Jobs');
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Text(_error, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_results.isEmpty) {
      return const SearchLoading(text: 'Job not found');
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) => VerticalTileWidget(job: _results[index]),
    );
  }
}
