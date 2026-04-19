import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/jobs/get_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/models/response/jobs/match_res_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/helpers/jobs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobsNotifier extends ChangeNotifier {
  // ── State fields ───────────────────────────────────────────────────────────
  List<JobsResponse> jobList = [];
  JobsResponse? recent;
  GetJobRes? currentJob;
  List<JobsResponse> userJobs = [];
  List<SwipedRes> swipedUsers = [];
  List<MatchedRes> matchedUsers = [];

  // ── Loading flags ──────────────────────────────────────────────────────────
  bool isLoadingJobList = false;
  bool isLoadingCurrentJob = false;
  bool isLoadingUserJobs = false;
  bool isLoadingSwipedUsers = false;

  // ── Preloaded in-memory feed for instant card rendering ───────────────────
  static const int _pageSize = 20;

  List<JobsResponse> cachedJobs = [];
  bool isLoadingJobs = false;
  bool isFetchingMore = false;
  bool isCreatingJob = false;
  bool hasMorePages = true;
  int _currentPage = 1;

  // ─── Feed preloading (paginated, cache-first) ─────────────────────────────

  /// Load page 1 from on-device cache immediately, then refresh from network.
  /// Resets pagination state — call on app start or after filter changes.
  Future<void> preloadJobs(
    String userId, {
    List<String> bookmarkedIds = const [],
  }) async {
    _currentPage = 1;
    hasMorePages = true;

    final cached = await JobsHelper.getCachedJobs(userId);
    if (cached.isNotEmpty) {
      cachedJobs = cached;
      notifyListeners();
    }

    isLoadingJobs = cachedJobs.isEmpty;
    if (cachedJobs.isEmpty) notifyListeners();

    final response = userId.isNotEmpty
        ? await JobsHelper.getFilteredJobsPaged(
            userId,
            1,
            _pageSize,
            excludeIds: bookmarkedIds,
          )
        : await JobsHelper.getJobsPaged(1, _pageSize);

    if (response.success && response.data != null) {
      cachedJobs = response.data!;
      hasMorePages = response.data!.length >= _pageSize;
      await JobsHelper.saveJobsCache(userId, response.data!);
    }

    isLoadingJobs = false;
    notifyListeners();
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

    _currentPage++;
    final response = userId.isNotEmpty
        ? await JobsHelper.getFilteredJobsPaged(
            userId,
            _currentPage,
            _pageSize,
            excludeIds: bookmarkedIds,
          )
        : await JobsHelper.getJobsPaged(_currentPage, _pageSize);

    if (response.success && response.data != null) {
      final next = response.data!;
      if (next.isEmpty || next.length < _pageSize) hasMorePages = false;
      if (next.isNotEmpty) {
        cachedJobs = [...cachedJobs, ...next];
        await JobsHelper.saveJobsCache(userId, cachedJobs);
      }
    } else {
      _currentPage--;
    }

    isFetchingMore = false;
    notifyListeners();
  }

  // ─── Get all jobs ──────────────────────────────────────────────────────────

  Future<void> getJobs() async {
    isLoadingJobList = true;
    notifyListeners();

    final response = await JobsHelper.getJobs();

    isLoadingJobList = false;

    if (response.success && response.data != null) {
      jobList = response.data!;
    } else {
      Get.snackbar(
        'Error Loading Jobs',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }

    notifyListeners();
  }

  // ─── Get filtered jobs ─────────────────────────────────────────────────────

  Future<void> getFilteredJobs(String agentId) async {
    isLoadingJobList = true;
    notifyListeners();

    final response = await JobsHelper.getFilteredJobs(agentId);

    isLoadingJobList = false;

    if (response.success && response.data != null) {
      jobList = response.data!;
    } else {
      Get.snackbar(
        'Error Loading Jobs',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }

    notifyListeners();
  }

  // ─── Get single job ────────────────────────────────────────────────────────

  Future<void> getJob(String jobId) async {
    isLoadingCurrentJob = true;
    currentJob = null;
    notifyListeners();

    final response = await JobsHelper.getJob(jobId);

    isLoadingCurrentJob = false;

    if (response.success && response.data != null) {
      currentJob = response.data;
    } else {
      Get.snackbar(
        'Error Loading Job',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }

    notifyListeners();
  }

  // ─── Get most recent job ───────────────────────────────────────────────────

  Future<void> getRecent() async {
    final response = await JobsHelper.getRecent();

    if (response.success && response.data != null) {
      recent = response.data;
      notifyListeners();
    } else {
      Get.snackbar(
        'Error',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }
  }

  // ─── Get jobs for a specific user ─────────────────────────────────────────

  Future<void> getUserJobs(String agentId) async {
    isLoadingUserJobs = true;
    notifyListeners();

    final response = await JobsHelper.getUserJobs(agentId);

    isLoadingUserJobs = false;

    if (response.success && response.data != null) {
      userJobs = response.data!;
    } else {
      Get.snackbar(
        'Error Loading Your Jobs',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }

    notifyListeners();
  }

  // ─── Load cached user jobs for instant display ────────────────────────────

  Future<void> loadCachedUserJobs(String agentId) async {
    final cached = await JobsHelper.getCachedUserJobs(agentId);
    if (cached.isNotEmpty) {
      userJobs = cached;
      notifyListeners();
    }
  }

  // ─── Displayable feed (filtered for current user) ─────────────────────────

  List<JobsResponse> getDisplayableJobs(
    String currentUserId, {
    List<String> bookmarkedIds = const [],
  }) {
    final bookmarkedSet = bookmarkedIds.toSet();
    return cachedJobs.where((j) {
      return j.agentId != currentUserId &&
          j.hiring == true &&
          !bookmarkedSet.contains(j.id);
    }).toList();
  }

  // ─── Create job ────────────────────────────────────────────────────────────

  Future<void> createJob(
    CreateJobsRequest model,
    BuildContext context, {
    File? imageFile,
  }) async {
    isCreatingJob = true;
    notifyListeners();

    final response = await JobsHelper.createJob(model, imageFile: imageFile);

    isCreatingJob = false;
    notifyListeners();

    if (response.success) {
      await getJobs();
      await getUserJobs(model.agentId);
      await preloadJobs(model.agentId);

      Get.snackbar(
        'Query Created Successfully',
        'Your job listing has been added.',
        colorText: kLight,
        backgroundColor: kLightBlue,
        icon: const Icon(Icons.check_circle),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF040326),
            title: const Text(
              'Failed to List Query',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              response.message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: kTealLight)),
              ),
            ],
          ),
        );
      }
    }
  }

  // ─── Update job ────────────────────────────────────────────────────────────

  Future<void> updateJob(String jobId, Map<String, dynamic> jobData) async {
    final response = await JobsHelper.updateJob(jobId, jobData);

    if (response.success) {
      await getJobs();
    } else {
      Get.snackbar(
        'Error Updating Job',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }
  }

  // ─── Delete job ────────────────────────────────────────────────────────────

  Future<void> deleteJob(String jobId) async {
    final response = await JobsHelper.deleteJob(jobId);

    if (response.success) {
      await getJobs();
    } else {
      Get.snackbar(
        'Error Deleting Job',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error_outline),
      );
    }
  }

  // ─── Swiped users ──────────────────────────────────────────────────────────

  Future<void> getSwipedUsersId(String jobId) async {
    isLoadingSwipedUsers = true;
    notifyListeners();

    final response = await JobsHelper.getSwipededUsersId(jobId);

    isLoadingSwipedUsers = false;

    if (response.success && response.data != null) {
      swipedUsers = response.data!;
    } else {
      swipedUsers = [];
    }

    notifyListeners();
  }

  Future<void> addSwipedUsers(
    String jobId,
    String userId,
    String action,
  ) async {
    // Fire-and-forget — no snackbar, runs silently in background
    await JobsHelper.addSwipedUsers(jobId, userId, action);
  }

  Future<void> undoSwipe(String jobId, String userId) async {
    await JobsHelper.undoSwipe(jobId, userId);
  }

  // ─── Matched users ─────────────────────────────────────────────────────────

  Future<void> getMatchedUsersId(String jobId) async {
    final response = await JobsHelper.getMatchedUsersId(jobId);

    if (response.success && response.data != null) {
      matchedUsers = response.data!;
      notifyListeners();
    } else {
      matchedUsers = [];
      notifyListeners();
    }
  }

  Future<void> addMatchedUsers(String jobId, String userId) async {
    // Fire-and-forget — runs silently in background
    await JobsHelper.addMatchedUsers(jobId, userId);
  }
}
