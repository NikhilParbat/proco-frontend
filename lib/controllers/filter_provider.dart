import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/request/filters/create_filter.dart';
import 'package:proco/models/response/filters/filter_response.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/helpers/filter_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterNotifier extends ChangeNotifier {
  List<FilterResponse> filterList = [];
  GetFilterRes? filter;
  List<FilterResponse> userFilters = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Active filter (shown as chips on homepage) ──────────────────────────
  GetFilterRes? activeFilter;

  FilterNotifier() {
    _loadActiveFilterFromPrefs();
  }

  Future<void> _loadActiveFilterFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('activeFilter');
    if (jsonStr != null) {
      try {
        activeFilter = getFilterResFromJson(jsonStr);
        notifyListeners();
      } catch (_) {}
    }
  }

  void setActiveFilter(GetFilterRes f) async {
    activeFilter = f;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeFilter', getFilterResToJson(f));
    notifyListeners();
  }

  Future<void> clearFilter(String agentId) async {
    final response = await FilterHelper.createFilter(
      CreateFilterRequest(
        agentId: agentId,
        selectedOptions: [],
        selectedLocationOption: '',
        selectedCity: '',
        selectedState: '',
        selectedCountry: '',
        customOptions: [],
        skills: [],
        sortByTime: false,
        postedWithin: '',
        internship: false,
        research: false,
        freelance: false,
        competition: false,
        collaborate: false,
      ),
    );

    if (!response.success) {
      Get.snackbar(
        'Error',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }

    activeFilter = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeFilter');
    notifyListeners();
  }

  Future<void> getFilters() async {
    _isLoading = true;
    notifyListeners();

    final response = await FilterHelper.getFilters();

    _isLoading = false;

    if (response.success && response.data != null) {
      filterList = response.data!;
    } else {
      Get.snackbar(
        'Error',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }

    notifyListeners();
  }

  Future<void> getFilter(String agentId) async {
    final response = await FilterHelper.getFilter(agentId);

    if (response.success && response.data != null) {
      filter = response.data;
      notifyListeners();
    } else {
      Get.snackbar(
        'Error',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }
  }

  Future<void> createFilter(String agentId, CreateFilterRequest model) async {
    final response = await FilterHelper.createFilter(model);

    if (response.success) {
      Get.snackbar(
        'Filter Applied',
        '',
        colorText: kLight,
        backgroundColor: kLightBlue,
        icon: const Icon(Icons.check_circle),
      );
      if (response.data != null) {
        filter = response.data;
        notifyListeners();
      }
    } else {
      Get.snackbar(
        'Error Saving Filter',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }
  }

  Future<void> updateFilter(String filterId, Map<String, dynamic> filterData) async {
    final response = await FilterHelper.updateFilter(filterId, filterData);

    if (!response.success) {
      Get.snackbar(
        'Error Updating Filter',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }
  }

  Future<void> deleteFilter(String filterId) async {
    final response = await FilterHelper.deleteFilter(filterId);

    if (!response.success) {
      Get.snackbar(
        'Error Deleting Filter',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }
  }
}
