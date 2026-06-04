import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/auth/profile_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:get/get.dart';

class ProfileNotifier extends ChangeNotifier {
  ProfileRes? _profile;
  ProfileRes? get profile => _profile;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  String? _profileError;
  String? get profileError => _profileError;

  List<SwipedRes> _swipedUsers = [];
  List<SwipedRes> get swipedUsers => _swipedUsers;

  bool _isLoadingSwipedUsers = false;
  bool get isLoadingSwipedUsers => _isLoadingSwipedUsers;

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  bool _isDeletingAccount = false;
  bool get isDeletingAccount => _isDeletingAccount;

  final Map<String, UserResponse> _fetchedUsers = {};

  // ─── Fetch own profile ────────────────────────────────────────────────────

  Future<void> getProfile() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    final response = await UserHelper.getProfile();

    if (response.success && response.data != null) {
      _profile = response.data;
      _profileError = null;
    } else {
      _profileError = response.message;
    }

    _isLoadingProfile = false;
    notifyListeners();
  }

  // ─── Fetch swiped users ───────────────────────────────────────────────────

  Future<void> getSwipedUsers(String agentId) async {
    _isLoadingSwipedUsers = true;
    notifyListeners();

    try {
      _swipedUsers = await UserHelper.getUserProfiles(agentId);
    } catch (e) {
      debugPrint('getSwipedUsers error: $e');
      _swipedUsers = [];
    }

    _isLoadingSwipedUsers = false;
    notifyListeners();
  }

  // ─── Fetch user by ID (cache-first via UserHelper) ─────────────────────────

  Future<UserResponse?> fetchUserById(String userId) async {
    final cached = _fetchedUsers[userId];
    if (cached != null) return cached;

    final response = await UserHelper.fetchUserById(userId);
    if (response.success && response.data != null) {
      _fetchedUsers[userId] = response.data!;
      notifyListeners();
      return response.data;
    }

    debugPrint('fetchUserById failed: ${response.message}');
    return null;
  }

  // ─── Update profile ───────────────────────────────────────────────────────
  Future<bool> updateProfile(ProfileUpdateReq model, XFile? image) async {
    _isUpdatingProfile = true;
    notifyListeners();

    final response = await UserHelper.updateProfile(model, image);

    _isUpdatingProfile = false;
    notifyListeners();

    if (response.success) {
      Get.snackbar(
        'Profile Update',
        response.message.isNotEmpty
            ? response.message
            : 'Profile updated successfully',
        colorText: kLight,
        backgroundColor: kLightBlue,
        icon: const Icon(Icons.check_circle),
      );
      return true;
    } else {
      Get.snackbar(
        'Update Failed',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }
  // ─── Create profile (onboarding) ──────────────────────────────────────────

  Future<String?> createProfile(ProfileUpdateReq model, XFile? image) async {
    _isUpdatingProfile = true;
    notifyListeners();

    final error = await UserHelper.createProfile(model, image);

    _isUpdatingProfile = false;
    notifyListeners();

    return error;
  }

  // ─── Delete account ───────────────────────────────────────────────────────

  Future<ApiResponse<void>> deleteAccount() async {
    _isDeletingAccount = true;
    notifyListeners();

    final response = await UserHelper.deleteAccount();

    _isDeletingAccount = false;
    notifyListeners();

    return response;
  }

  // ─── Clear cache on logout ────────────────────────────────────────────────

  void clearCache() {
    UserHelper.clearUserCache();
    _fetchedUsers.clear();
    _profile = null;
    _swipedUsers = [];
    _profileError = null;
    notifyListeners();
  }
}
