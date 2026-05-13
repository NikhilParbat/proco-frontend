import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';

void showErrorSnackbar(String message, {String title = 'Error'}) {
  Get.snackbar(
    title,
    message,
    colorText: kLight,
    backgroundColor: kOrange,
    icon: const Icon(Icons.error),
  );
}
