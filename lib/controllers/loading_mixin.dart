import 'package:flutter/material.dart';

mixin LoadingMixin on ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> runWithLoading(Future<void> Function() fn) async {
    _isLoading = true;
    notifyListeners();
    try {
      await fn();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
