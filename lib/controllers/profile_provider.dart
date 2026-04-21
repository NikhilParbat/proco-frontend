import 'dart:io';

import 'package:flutter/material.dart';
import 'package:proco/models/response/api_response.dart';
import 'package:proco/models/response/auth/profile_model.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/models/response/user/user_response.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/auth/profile_update_model.dart';
import 'package:proco/views/ui/mainscreen.dart';

class ProfileNotifier extends ChangeNotifier {
  // Fix: make nullable for proper push to home after login

  Future<ApiResponse<ProfileRes>>? profile;
  Future<List<SwipedRes>>? swipedUsers;

  void getProfile() async {
    profile = UserHelper.getProfile();
    notifyListeners();
  }

  void getSwipedUsers(dynamic agentId) async {
    swipedUsers = UserHelper.getUserProfiles(agentId);
    notifyListeners();
  }

  void updateProfile(ProfileUpdateReq model, File? image) async {
    final response = await UserHelper.updateProfile(model, image);

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

      // Optional: you now have updated user data
      final user = response.data;
      if (user != null) {
        debugPrint("Updated user: ${user.username}");
      }

      Future.delayed(const Duration(seconds: 2), () {
        Get.offAll(() => const MainScreen());
      });
    } else {
      Get.snackbar(
        'Update Failed',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
        duration: const Duration(seconds: 5),
      );
    }
  }
}
