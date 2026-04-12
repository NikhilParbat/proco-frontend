import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/jobs/get_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/services/helpers/jobs_helper.dart';

import '../models/response/jobs/match_res_model.dart';

class JobsNotifier extends ChangeNotifier {
  Future<List<JobsResponse>>? jobList;
  Future<JobsResponse>? recent;
  Future<GetJobRes>? job;
  Future<List<JobsResponse>>? userJobs;
  Future<List<SwipedRes>>? swipedUsers;
  Future<List<MatchedRes>>? matchedUsers;

  // ── Preloaded in-memory feed for instant card rendering ──────────────────
  static const int _pageSize = 20;

  List<JobsResponse> cachedJobs = [];
  bool isLoadingJobs = false;
  bool isFetchingMore = false;
  bool isCreatingJob = false;
  bool hasMorePages = true;
  int _currentPage = 1;

  /// Load page 1 from on-device cache immediately, then refresh from network.
  /// Resets pagination state — call this on app start or after filter changes.
  Future<void> preloadJobs(
    String userId, {
    List<String> bookmarkedIds = const [],
  }) async {
    _currentPage = 1;
    hasMorePages = true;

    // 1. Show cached cards right away (no spinner)
    final cached = await JobsHelper.getCachedJobs(userId);
    if (cached.isNotEmpty) {
      cachedJobs = cached;
      notifyListeners();
    }

    // 2. Fetch page 1 from network in background
    isLoadingJobs = cachedJobs.isEmpty;
    if (cachedJobs.isEmpty) notifyListeners();

    try {
      final fresh = userId.isNotEmpty
          ? await JobsHelper.getFilteredJobsPaged(
              userId,
              1,
              _pageSize,
              excludeIds: bookmarkedIds,
            )
          : await JobsHelper.getJobsPaged(1, _pageSize);
      cachedJobs = fresh;
      hasMorePages = fresh.length >= _pageSize;
      await JobsHelper.saveJobsCache(userId, fresh);
    } catch (_) {
      // keep cached data if network fails
    } finally {
      isLoadingJobs = false;
      notifyListeners();
    }
  }

  /// Silently fetch the next page and append — called when remaining cards
  /// drop below the percentage threshold set in JobCardSwiper.
  Future<void> loadNextPage(
    String userId, {
    List<String> bookmarkedIds = const [],
  }) async {
    if (isFetchingMore || !hasMorePages) return;
    isFetchingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final next = userId.isNotEmpty
          ? await JobsHelper.getFilteredJobsPaged(
              userId,
              _currentPage,
              _pageSize,
              excludeIds: bookmarkedIds,
            )
          : await JobsHelper.getJobsPaged(_currentPage, _pageSize);

      if (next.isEmpty || next.length < _pageSize) hasMorePages = false;

      if (next.isNotEmpty) {
        cachedJobs = [...cachedJobs, ...next];
        await JobsHelper.saveJobsCache(userId, cachedJobs);
      }
    } catch (_) {
      _currentPage--; // rollback so next attempt retries the same page
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  void getJobs() {
    jobList = JobsHelper.getJobs();
    notifyListeners();
  }

  void getFilteredJobs(String agentId) {
    jobList = JobsHelper.getFilteredJobs(agentId);
    notifyListeners();
  }

  void getRecent() {
    recent = JobsHelper.getRecent();
    notifyListeners();
  }

  void getJob(String jobId) {
    job = JobsHelper.getJob(jobId);
    notifyListeners();
  }

  List<JobsResponse> getDisplayableJobs(
    String currentUserId, {
    List<String> bookmarkedIds = const [],
  }) {
    final bookmarkedSet = bookmarkedIds.toSet();
    return cachedJobs.where((job) {
      final isNotMine = job.agentId != currentUserId;
      final isHiring = job.hiring == true;
      final isNotBookmarked = !bookmarkedSet.contains(job.id);
      return isNotMine && isHiring && isNotBookmarked;
    }).toList();
  }

  Future<void> createJob(
    CreateJobsRequest model,
    context, {
    File? imageFile,
  }) async {
    isCreatingJob = true;
    notifyListeners();

    try {
      await JobsHelper.createJob(model, imageFile: imageFile).then((_) async {
        // Refresh both the global job list and the user's own job list
        getJobs();
        getUserJobs(model.agentId);
        preloadJobs(model.agentId);

        // Show success message
        Get.snackbar(
          'Query Created Successfully',
          'Your job listing has been added in {model.location}.',
          colorText: kLight,
          backgroundColor: kLightBlue,
          icon: const Icon(Icons.check_circle),
        );

        isCreatingJob = false;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();
      });
    } catch (e) {
      isCreatingJob = false;
      notifyListeners();
      debugPrint('createJob error: $e');
      _showErrorDialog(context, e.toString());
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF040326),
        title: const Text(
          'Failed to List Query',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: kTealLight)),
          ),
        ],
      ),
    );
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> jobData) async {
    await JobsHelper.updateJob(jobId, jobData);
    getJobs(); // Refresh the job list after update
  }

  Future<void> deleteJob(String jobId) async {
    await JobsHelper.deleteJob(jobId);
    getJobs(); // Refresh the job list after deletion
  }

  // Show cached jobs instantly, then refresh from network in background
  Future<void> loadCachedUserJobs(String agentId) async {
    final cached = await JobsHelper.getCachedUserJobs(agentId);
    if (cached.isNotEmpty) {
      userJobs = Future.value(cached);
      notifyListeners();
    }
  }

  // Add the new function to fetch jobs for a specific user
  void getUserJobs(String agentId) {
    userJobs = JobsHelper.getUserJobs(agentId);
    notifyListeners();
  }

  void getSwipedUsersId(String jobId) {
    swipedUsers = JobsHelper.getSwipededUsersId(jobId);
    notifyListeners();
  }

  void addSwipedUsers(String jobId, String userId, String action) {
    JobsHelper.addSwipedUsers(jobId, userId, action);
    notifyListeners();
  }

  void undoSwipe(String jobId, String userId) {
    JobsHelper.undoSwipe(jobId, userId);
    notifyListeners();
  }

  void getMatchedUsersId(String jobId) {
    matchedUsers = JobsHelper.getMatchedUsersId(jobId);
    notifyListeners();
  }

  void addMatchedUsers(String jobId, String userId) {
    JobsHelper.addMatchedUsers(jobId, userId);
    notifyListeners();
  }
}
