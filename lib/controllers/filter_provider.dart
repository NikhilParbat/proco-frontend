import 'package:flutter/material.dart';
import 'package:proco/controllers/loading_mixin.dart';
import 'package:proco/models/request/filters/create_filter.dart';
import 'package:proco/models/response/filters/filter_response.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/helpers/filter_helper.dart';
import 'package:proco/views/common/lagoon_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterNotifier extends ChangeNotifier with LoadingMixin {
  List<FilterResponse> filterList = [];
  GetFilterRes? filter;
  List<FilterResponse> userFilters = [];

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
        selectedDomains: const [],
        opportunityTypes: const [],
        selectedLocationOption: '',
        selectedCity: '',
        selectedState: '',
        selectedCountry: '',
        distanceKm: 0,
        skills: const [],
        postedWithin: '',
      ),
    );

    if (!response.success) {
      LagoonSnackbar.showError(
        message: response.message,
        title: "Error Clearing Filter",
      );
    }

    activeFilter = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeFilter');
    notifyListeners();
  }

  Future<void> loadFilterForUser(String userId) async {
    if (userId.isEmpty) return;
    final response = await FilterHelper.getFilter(userId);
    if (response.success && response.data != null) {
      setActiveFilter(response.data!);
    }
  }

  Future<void> getFilters() async {
    await runWithLoading(() async {
      final response = await FilterHelper.getFilters();
      if (response.success && response.data != null) {
        filterList = response.data!;
      } else {
        LagoonSnackbar.showError(
          message: response.message,
          title: "Error Fetching Filters",
        );
      }
    });
  }

  Future<void> getFilter(String agentId) async {
    final response = await FilterHelper.getFilter(agentId);

    if (response.success && response.data != null) {
      filter = response.data;
      notifyListeners();
    } else {
      LagoonSnackbar.showError(
        message: response.message,
        title: "Error Fetching filter",
      );
    }
  }

  Future<bool> createFilter(String agentId, CreateFilterRequest model) async {
    final response = await FilterHelper.createFilter(model);

    if (response.success) {
      LagoonSnackbar.show(title: 'Filter Applied', message: response.message);
      if (response.data != null) {
        filter = response.data;
        setActiveFilter(response.data!);
      }
      return true;
    } else {
      LagoonSnackbar.showError(
        message: response.message,
        title: 'Error Saving Filter',
      );
      return false;
    }
  }

  Future<void> updateFilter(
    String filterId,
    Map<String, dynamic> filterData,
  ) async {
    final response = await FilterHelper.updateFilter(filterId, filterData);

    if (!response.success) {
      LagoonSnackbar.showError(
        message: response.message,
        title: 'Error Updating Filter',
      );
    }
  }

  Future<void> deleteFilter(String filterId) async {
    final response = await FilterHelper.deleteFilter(filterId);

    if (!response.success) {
      LagoonSnackbar.showError(
        title: 'Error Deleting Filter',
        message: response.message,
      );
    }
  }
}
