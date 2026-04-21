import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/bookmarks/bookmarks_model.dart';
import 'package:proco/models/response/bookmarks/all_bookmarks.dart';
import 'package:proco/services/helpers/book_helper.dart';
import 'package:proco/services/helpers/jobs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookMarkNotifier extends ChangeNotifier {
  // ── Local ID cache (persisted to SharedPreferences for offline checks) ──────
  List<String> _jobs = [];
  List<String> get jobs => _jobs;

  // ── Bookmark list (populated from backend) ───────────────────────────────────
  List<AllBookmark> bookmarks = [];

  // ── Loading state ─────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BookMarkNotifier() {
    loadJobs();
  }

  // ─── Local ID cache helpers ───────────────────────────────────────────────

  Future<void> loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('jobId');
    if (saved != null) {
      _jobs = saved;
      notifyListeners();
    }
  }

  Future<void> _addJob(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    _jobs.insert(0, jobId);
    await prefs.setStringList('jobId', _jobs);
    notifyListeners();
  }

  Future<void> _removeJob(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    _jobs.remove(jobId);
    await prefs.setStringList('jobId', _jobs);
    notifyListeners();
  }

  // ─── Add bookmark ──────────────────────────────────────────────────────────

  Future<void> addBookMark(BookmarkReqResModel model, String jobId) async {
    final response = await BookMarkHelper.addBookmarks(model);

    if (response.success) {
      await _addJob(jobId);
      Get.snackbar(
        'Bookmark Added',
        'Please check your bookmarks',
        colorText: kLight,
        backgroundColor: kLightBlue,
        icon: const Icon(Icons.bookmark_add),
      );
    } else {
      Get.snackbar(
        'Failed to Add Bookmark',
        response.message,
        colorText: kLight,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.bookmark_add),
      );
    }
  }

  // ─── Delete bookmark ───────────────────────────────────────────────────────

  Future<void> deleteBookMark(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final response = await BookMarkHelper.deleteBookmarks(jobId);

    if (response.success) {
      await _removeJob(jobId);
      bookmarks.removeWhere((b) => b.job.id == jobId || b.id == jobId);
      notifyListeners();

      if (userId.isNotEmpty) {
        JobsHelper.addSwipedUsers(jobId, userId, 'left');
      }

      Get.snackbar(
        'Bookmark Deleted',
        'Please check your bookmarks',
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.bookmark_remove_outlined),
      );
    } else {
      Get.snackbar(
        'Failed to Delete Bookmark',
        response.message,
        colorText: kLight,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.bookmark_remove_outlined),
      );
    }
  }

  // ─── Get all bookmarks ─────────────────────────────────────────────────────

  Future<void> getBookMarks() async {
    _isLoading = true;
    notifyListeners();

    final response = await BookMarkHelper.getBookmarks();

    _isLoading = false;

    if (response.success && response.data != null) {
      bookmarks = response.data!;

      // Sync local ID cache so SharedPreferences reflects only live bookmarks
      final activeIds = bookmarks.map((b) => b.job.id).where((id) => id.isNotEmpty).toList();
      final prefs = await SharedPreferences.getInstance();
      _jobs = activeIds;
      await prefs.setStringList('jobId', _jobs);
    } else {
      Get.snackbar(
        'Failed to Load Bookmarks',
        response.message,
        colorText: kLight,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.error_outline),
      );
    }

    notifyListeners();
  }
}
