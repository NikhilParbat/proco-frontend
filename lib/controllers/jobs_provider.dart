import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/jobs/get_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/models/response/jobs/match_res_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/helpers/jobs_helper.dart';
import 'package:proco/utils/debouncer.dart';

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
  List<JobsResponse> _displayJobs = [];
  bool _displayDirty = true;

  // ✅ Debouncer for rapid preload calls
  final _preloadDebouncer = Debouncer(milliseconds: 300);
  final _nextPageDebouncer = Debouncer(milliseconds: 500);

  // ✅ Cache last request to prevent duplicate calls
  String? _lastPreloadUserId;
  List<String> _lastBookmarkedIds = [];

  // ─── Feed preloading (paginated, cache-first) ─────────────────────────────

  /// Load page 1 from on-device cache immediately, then refresh from network.
  /// Resets pagination state — call on app start or after filter changes.
  Future<void> preloadJobs(
    String userId, {
    List<String> bookmarkedIds = const [],
  }) async {
    // ✅ Prevent duplicate calls with same parameters
    if (_lastPreloadUserId == userId &&
        _listEquals(_lastBookmarkedIds, bookmarkedIds) &&
        cachedJobs.isNotEmpty) {
      return;
    }

    _lastPreloadUserId = userId;
    _lastBookmarkedIds = List.from(bookmarkedIds);

    // ✅ Debounce rapid calls
    _preloadDebouncer.run(() => _executePreloadJobs(userId, bookmarkedIds));
  }

  Future<void> _executePreloadJobs(
    String userId,
    List<String> bookmarkedIds,
  ) async {
    _currentPage = 1;
    hasMorePages = true;

    JobsHelper.getCachedJobs(userId).then((cached) {
      if (cached.isNotEmpty && cachedJobs.isEmpty) {
        cachedJobs = cached;
        notifyListeners();
      }
    });

    isLoadingJobs = cachedJobs.isEmpty;
    if (cachedJobs.isEmpty) notifyListeners();

    // ✅ Network request in background
    try {
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
        _displayDirty = true;
        hasMorePages = response.data!.length >= _pageSize;

        // ✅ Save cache in background (don't await)
        JobsHelper.saveJobsCache(userId, response.data!).catchError((e) {
          debugPrint('Cache save error: $e');
        });
      }
    } catch (e) {
      debugPrint('Preload jobs error: $e');
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

    // ✅ Debounce rapid pagination requests
    _nextPageDebouncer.run(() => _executeLoadNextPage(userId, bookmarkedIds));
  }

  Future<void> _executeLoadNextPage(
    String userId,
    List<String> bookmarkedIds,
  ) async {
    if (isFetchingMore || !hasMorePages) return;

    isFetchingMore = true;
    notifyListeners();

    _currentPage++;

    try {
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
          cachedJobs.addAll(next); // ✅ also optimized (no list copy)

          _displayDirty = true; // 🔥 ADD THIS LINE

          // ✅ Save cache in background
          JobsHelper.saveJobsCache(userId, cachedJobs).catchError((e) {
            debugPrint('Cache save error: $e');
          });
        }
      } else {
        _currentPage--;
      }
    } catch (e) {
      debugPrint('Load next page error: $e');
      _currentPage--;
    }

    isFetchingMore = false;
    notifyListeners();
  }

  // ─── Get all jobs ──────────────────────────────────────────────────────────

  Future<void> getJobs() async {
    if (isLoadingJobList) return; // ✅ Prevent duplicate calls

    isLoadingJobList = true;
    notifyListeners();

    try {
      final response = await JobsHelper.getJobs();

      if (response.success && response.data != null) {
        jobList = response.data!;
      } else {
        _showErrorSnackbar('Error Loading Jobs', response.message);
      }
    } catch (e) {
      debugPrint('Get jobs error: $e');
      _showErrorSnackbar('Error Loading Jobs', e.toString());
    }

    isLoadingJobList = false;
    notifyListeners();
  }

  // ─── Get filtered jobs ─────────────────────────────────────────────────────

  Future<void> getFilteredJobs(String agentId) async {
    if (isLoadingJobList) return;

    isLoadingJobList = true;
    notifyListeners();

    try {
      final response = await JobsHelper.getFilteredJobs(agentId);

      if (response.success && response.data != null) {
        jobList = response.data!;
      } else {
        _showErrorSnackbar('Error Loading Jobs', response.message);
      }
    } catch (e) {
      debugPrint('Get filtered jobs error: $e');
      _showErrorSnackbar('Error Loading Jobs', e.toString());
    }

    isLoadingJobList = false;
    notifyListeners();
  }

  // ─── Get single job ────────────────────────────────────────────────────────

  Future<void> getJob(String jobId) async {
    if (isLoadingCurrentJob) return;

    isLoadingCurrentJob = true;
    currentJob = null;
    notifyListeners();

    try {
      final response = await JobsHelper.getJob(jobId);

      if (response.success && response.data != null) {
        currentJob = response.data;
      } else {
        _showErrorSnackbar('Error Loading Job', response.message);
      }
    } catch (e) {
      debugPrint('Get job error: $e');
      _showErrorSnackbar('Error Loading Job', e.toString());
    }

    isLoadingCurrentJob = false;
    notifyListeners();
  }

  // ─── Get most recent job ───────────────────────────────────────────────────

  Future<void> getRecent() async {
    try {
      final response = await JobsHelper.getRecent();

      if (response.success && response.data != null) {
        recent = response.data;
        notifyListeners();
      } else {
        _showErrorSnackbar('Error', response.message);
      }
    } catch (e) {
      debugPrint('Get recent error: $e');
    }
  }

  // ─── Get jobs for a specific user ─────────────────────────────────────────

  Future<void> getUserJobs(String agentId) async {
    if (isLoadingUserJobs) return;

    // ✅ Load from cache first
    await loadCachedUserJobs(agentId);

    isLoadingUserJobs = true;
    notifyListeners();

    try {
      final response = await JobsHelper.getUserJobs(agentId);

      if (response.success && response.data != null) {
        userJobs = response.data!;

        // ✅ Save to cache in background
        JobsHelper.saveCachedUserJobs(agentId, response.data!).catchError((e) {
          debugPrint('User jobs cache save error: $e');
        });
      } else {
        _showErrorSnackbar('Error Loading Your Jobs', response.message);
      }
    } catch (e) {
      debugPrint('Get user jobs error: $e');
      _showErrorSnackbar('Error Loading Your Jobs', e.toString());
    }

    isLoadingUserJobs = false;
    notifyListeners();
  }

  // ─── Load cached user jobs for instant display ────────────────────────────

  Future<void> loadCachedUserJobs(String agentId) async {
    try {
      final cached = await JobsHelper.getCachedUserJobs(agentId);
      if (cached.isNotEmpty) {
        userJobs = cached;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load cached user jobs error: $e');
    }
  }

  // ─── Displayable feed (filtered for current user) ─────────────────────────
  List<JobsResponse> getDisplayableJobs(
    String currentUserId, {
    List<String> bookmarkedIds = const [],
  }) {
    if (!_displayDirty) return _displayJobs;

    final bookmarkedSet = bookmarkedIds.toSet();

    _displayJobs = cachedJobs.where((j) {
      return j.agentId != currentUserId &&
          j.hiring == true &&
          !bookmarkedSet.contains(j.id);
    }).toList();

    _displayDirty = false;
    return _displayJobs;
  }

  // ─── Create job ────────────────────────────────────────────────────────────

  Future<void> createJob(
    CreateJobsRequest model,
    BuildContext context, {
    File? imageFile,
  }) async {
    if (isCreatingJob) return;

    isCreatingJob = true;
    notifyListeners();

    try {
      final response = await JobsHelper.createJob(model, imageFile: imageFile);

      if (response.success) {
        // ✅ Optimized: Run in parallel, don't block UI
        Future.wait([
          getJobs(),
          getUserJobs(model.agentId),
          preloadJobs(model.agentId),
        ]).catchError((e) {
          debugPrint('Post-create refresh error: $e');
          return <List<void>>[];
        });

        Get.snackbar(
          'Query Created Successfully',
          'Your job listing has been added.',
          colorText: kLight,
          backgroundColor: kLightBlue,
          icon: const Icon(Icons.check_circle),
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        Get.back();
      } else {
        if (context.mounted) {
          _showCreateJobErrorDialog(context, response.message);
        }
      }
    } catch (e) {
      debugPrint('Create job error: $e');
      if (context.mounted) {
        _showCreateJobErrorDialog(context, e.toString());
      }
    }

    isCreatingJob = false;
    notifyListeners();
  }

  // ─── Update job ────────────────────────────────────────────────────────────

  Future<void> updateJob(String jobId, Map<String, dynamic> jobData) async {
    try {
      final response = await JobsHelper.updateJob(jobId, jobData);

      if (response.success) {
        await getJobs();
      } else {
        _showErrorSnackbar('Error Updating Job', response.message);
      }
    } catch (e) {
      debugPrint('Update job error: $e');
      _showErrorSnackbar('Error Updating Job', e.toString());
    }
  }

  // ─── Delete job ────────────────────────────────────────────────────────────

  Future<void> deleteJob(String jobId) async {
    try {
      final response = await JobsHelper.deleteJob(jobId);

      if (response.success) {
        await getJobs();
      } else {
        _showErrorSnackbar('Error Deleting Job', response.message);
      }
    } catch (e) {
      debugPrint('Delete job error: $e');
      _showErrorSnackbar('Error Deleting Job', e.toString());
    }
  }

  // ─── Swiped users ──────────────────────────────────────────────────────────

  Future<void> getSwipedUsersId(String jobId) async {
    if (isLoadingSwipedUsers) return;

    isLoadingSwipedUsers = true;
    notifyListeners();

    try {
      final response = await JobsHelper.getSwipededUsersId(jobId);

      if (response.success && response.data != null) {
        swipedUsers = response.data!;
      } else {
        swipedUsers = [];
      }
    } catch (e) {
      debugPrint('Get swiped users error: $e');
      swipedUsers = [];
    }

    isLoadingSwipedUsers = false;
    notifyListeners();
  }

  Future<void> addSwipedUsers(
    String jobId,
    String userId,
    String action,
  ) async {
    // ✅ Fire-and-forget with error handling
    JobsHelper.addSwipedUsers(jobId, userId, action).catchError((e) {
      debugPrint('Add swiped users error: $e');
      return ApiResponse(success: false, message: e.toString());
    });
  }

  Future<void> undoSwipe(String jobId, String userId) async {
    try {
      await JobsHelper.undoSwipe(jobId, userId);
    } catch (e) {
      debugPrint('Undo swipe error: $e');
    }
  }

  // ─── Matched users ─────────────────────────────────────────────────────────

  Future<void> getMatchedUsersId(String jobId) async {
    try {
      final response = await JobsHelper.getMatchedUsersId(jobId);

      if (response.success && response.data != null) {
        matchedUsers = response.data!;
      } else {
        matchedUsers = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Get matched users error: $e');
      matchedUsers = [];
      notifyListeners();
    }
  }

  Future<void> addMatchedUsers(String jobId, String userId) async {
    // ✅ Fire-and-forget with error handling
    JobsHelper.addMatchedUsers(jobId, userId).catchError((e) {
      debugPrint('Add matched users error: $e');
      return ApiResponse(success: false, message: e.toString());
    });
  }

  // ✅ Helper methods ────────────────────────────────────────────────────────

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      colorText: kLight,
      backgroundColor: kOrange,
      icon: const Icon(Icons.error_outline),
      duration: const Duration(seconds: 3),
    );
  }

  void _showCreateJobErrorDialog(BuildContext context, String message) {
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

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ✅ Clean up resources
  @override
  void dispose() {
    _preloadDebouncer.dispose();
    _nextPageDebouncer.dispose();
    super.dispose();
  }
}
