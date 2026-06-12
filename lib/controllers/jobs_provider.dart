import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/jobs/get_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:proco/models/response/jobs/match_res_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/helpers/jobs_helper.dart';
import 'package:proco/utils/debouncer.dart';
import 'package:proco/views/common/lagoon_snackbar.dart';

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

  final _preloadDebouncer = Debouncer(milliseconds: 300);
  final _nextPageDebouncer = Debouncer(milliseconds: 500);

  String? _lastPreloadUserId;
  List<String> _lastBookmarkedIds = [];

  // ─── Feed preloading ──────────────────────────────────────────────────────

  Future<void> preloadJobs(
    String userId, {
    List<String> bookmarkedIds = const [],
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _lastPreloadUserId == userId &&
        _listEquals(_lastBookmarkedIds, bookmarkedIds) &&
        cachedJobs.isNotEmpty) {
      return;
    }

    _lastPreloadUserId = userId;
    _lastBookmarkedIds = List.from(bookmarkedIds);

    if (forceRefresh) {
      cachedJobs = [];
      _displayDirty = true;
      notifyListeners();
    }

    _preloadDebouncer.run(
      () => _executePreloadJobs(
        userId,
        bookmarkedIds,
        skipDiskCache: forceRefresh,
      ),
    );
  }

  Future<void> _executePreloadJobs(
    String userId,
    List<String> bookmarkedIds, {
    bool skipDiskCache = false,
  }) async {
    _currentPage = 1;
    hasMorePages = true;

    if (!skipDiskCache) {
      JobsHelper.getCachedJobs(userId).then((cached) {
        if (cached.isNotEmpty && cachedJobs.isEmpty) {
          cachedJobs = cached;
          notifyListeners();
        }
      });
    }

    isLoadingJobs = cachedJobs.isEmpty;
    if (cachedJobs.isEmpty) notifyListeners();

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

  Future<void> loadNextPage(
    String userId, {
    List<String> bookmarkedIds = const [],
  }) async {
    if (isFetchingMore || !hasMorePages) return;
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
          cachedJobs.addAll(next);
          _displayDirty = true;
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
    if (isLoadingJobList) return;

    isLoadingJobList = true;
    notifyListeners();

    try {
      final response = await JobsHelper.getJobs();
      if (response.success && response.data != null) {
        jobList = response.data!;
      } else {
        LagoonSnackbar.showError(
          message: response.message,
          title: 'Error Loading Jobs',
        );
      }
    } catch (e) {
      debugPrint('Get jobs error: $e');
      LagoonSnackbar.showError(
        title: 'Error Loading Jobs',
        message: e.toString(),
      );
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
        LagoonSnackbar.showError(
          title: 'Error Loading Jobs',
          message: response.message,
        );
      }
    } catch (e) {
      debugPrint('Get filtered jobs error: $e');
      LagoonSnackbar.showError(
        title: 'Error Loading Jobs',
        message: e.toString(),
      );
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
        LagoonSnackbar.showError(
          title: 'Error Loading Job',
          message: response.message,
        );
      }
    } catch (e) {
      debugPrint('Get job error: $e');
      LagoonSnackbar.showError(
        title: 'Error Loading Job',
        message: e.toString(),
      );
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
        LagoonSnackbar.showError(title: 'Error', message: response.message);
      }
    } catch (e) {
      debugPrint('Get recent error: $e');
    }
  }

  // ─── Get jobs for a specific user ─────────────────────────────────────────

  Future<void> getUserJobs(String agentId) async {
    if (isLoadingUserJobs) return;

    await loadCachedUserJobs(agentId);

    isLoadingUserJobs = true;
    notifyListeners();

    try {
      final response = await JobsHelper.getUserJobs(agentId);
      if (response.success && response.data != null) {
        userJobs = response.data!;
        JobsHelper.saveCachedUserJobs(agentId, response.data!).catchError((e) {
          debugPrint('User jobs cache save error: $e');
        });
      } else {
        LagoonSnackbar.showError(
          title: 'Error Loading Your Jobs',
          message: response.message,
        );
      }
    } catch (e) {
      debugPrint('Get user jobs error: $e');
      LagoonSnackbar.showError(
        title: 'Error Loading Your Jobs',
        message: e.toString(),
      );
    }

    isLoadingUserJobs = false;
    notifyListeners();
  }

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

  // ─── Displayable feed ─────────────────────────────────────────────────────

  List<JobsResponse> getDisplayableJobs(
    String currentUserId, {
    List<String> bookmarkedIds = const [],
  }) {
    if (!_displayDirty) return _displayJobs;

    final bookmarkedSet = bookmarkedIds.toSet();
    _displayJobs = cachedJobs.where((j) {
      return j.agentId != currentUserId &&
          j.isActive == true &&
          !bookmarkedSet.contains(j.id);
    }).toList();

    _displayDirty = false;
    return _displayJobs;
  }

  // ─── Create job ────────────────────────────────────────────────────────────

  Future<void> createJob(
    CreateJobsRequest model,
    BuildContext context, {
    XFile? imageFile,
  }) async {
    if (isCreatingJob) return;

    isCreatingJob = true;
    notifyListeners();

    try {
      final response = await JobsHelper.createJob(model, imageFile: imageFile);

      if (response.success) {
        Future.wait([
          getJobs(),
          getUserJobs(model.agentId),
          preloadJobs(model.agentId),
        ]).catchError((e) {
          debugPrint('Post-create refresh error: $e');
          return <List<void>>[];
        });

        LagoonSnackbar.show(
          title: 'Opportunity Created Successfully',
          message: 'Your opportunity listing has been added.',
        );

        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
      } else {
        if (context.mounted)
          _showCreateJobErrorDialog(context, response.message);
      }
    } catch (e) {
      debugPrint('Create job error: $e');
      if (context.mounted) _showCreateJobErrorDialog(context, e.toString());
    }

    isCreatingJob = false;
    notifyListeners();
  }

  // ─── Update job ────────────────────────────────────────────────────────────

  Future<void> updateJob(
    String jobId,
    CreateJobsRequest model,
    BuildContext context, {
    XFile? imageFile,
  }) async {
    if (isCreatingJob) return;

    isCreatingJob = true;
    notifyListeners();

    try {
      final response = await JobsHelper.updateJob(
        jobId,
        model,
        imageFile: imageFile,
      );

      if (response.success) {
        Future.wait([
          getJobs(),
          getUserJobs(model.agentId),
          preloadJobs(model.agentId),
        ]).catchError((e) {
          debugPrint('Post-update refresh error: $e');
          return <List<void>>[];
        });

        LagoonSnackbar.show(
          title: 'Opportunity Updated Successfully',
          message: 'Your changes have been saved.',
        );

        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
      } else {
        if (context.mounted)
          _showCreateJobErrorDialog(context, response.message);
      }
    } catch (e) {
      debugPrint('Update job error: $e');
      if (context.mounted) _showCreateJobErrorDialog(context, e.toString());
    }

    isCreatingJob = false;
    notifyListeners();
  }

  // ─── Delete job ────────────────────────────────────────────────────────────

  Future<bool> deleteJob(String jobId) async {
    try {
      final response = await JobsHelper.deleteJob(jobId);
      if (response.success) {
        await getJobs();
        return true;
      }
      LagoonSnackbar.showError(
        title: 'Error Deleting Job',
        message: response.message,
      );
      return false;
    } catch (e) {
      debugPrint('Delete job error: $e');
      LagoonSnackbar.showError(
        title: 'Error Deleting Job',
        message: e.toString(),
      );
      return false;
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
    JobsHelper.addMatchedUsers(jobId, userId).catchError((e) {
      debugPrint('Add matched users error: $e');
      return ApiResponse(success: false, message: e.toString());
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showCreateJobErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF040326),
        title: const Text(
          'Failed to List Opportunity',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00BCD4))),
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

  @override
  void dispose() {
    _preloadDebouncer.dispose();
    _nextPageDebouncer.dispose();
    super.dispose();
  }
}
