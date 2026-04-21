import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/models/response/chat/get_chat.dart';
import 'package:proco/services/helpers/chat_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatNotifier extends ChangeNotifier {
  List<GetChats> chats = [];
  bool isLoading = false;

  List<String> _online = [];
  bool _typing = false;

  bool get typing => _typing;

  set typingStatus(bool newState) {
    _typing = newState;
    notifyListeners();
  }

  List<String> get online => _online;

  set onlineUsers(List<String> newList) {
    _online = newList;
    notifyListeners();
  }

  String? userId;

  // Optimistic local pin state while API call is in flight
  final Map<String, bool> _localPinOverride = {};

  bool isPinned(String chatId) => _localPinOverride[chatId] ?? false;

  /// ================= LOAD CHATS =================
  Future<void> getChats() async {
    isLoading = true;
    notifyListeners();

    final response = await ChatHelper.getConversations();

    isLoading = false;

    if (response.success && response.data != null) {
      chats = response.data!;
      for (final c in chats) {
        _localPinOverride[c.id] = c.isPinned;
      }
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

  /// ================= GET USER ID =================
  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    notifyListeners();
  }

  /// ================= TOGGLE PIN =================
  Future<void> togglePin(String chatId) async {
    final current = _localPinOverride[chatId] ?? false;
    _localPinOverride[chatId] = !current;
    notifyListeners();

    final response = await ChatHelper.togglePin(chatId);
    if (response.success && response.data != null) {
      _localPinOverride[chatId] = response.data!;
    } else {
      _localPinOverride[chatId] = current;
    }
    notifyListeners();
  }

  /// ================= UNMATCH =================
  Future<void> unmatchChat(String chatId) async {
    chats = chats.where((c) => c.id != chatId).toList();
    _localPinOverride.remove(chatId);
    notifyListeners();

    final response = await ChatHelper.unmatchChat(chatId);
    if (!response.success) {
      Get.snackbar(
        'Error',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }
  }

  /// ================= CLEAR CHAT =================
  Future<void> clearChat(String chatId) async {
    final response = await ChatHelper.clearChat(chatId);
    if (!response.success) {
      Get.snackbar(
        'Error',
        response.message,
        colorText: kLight,
        backgroundColor: kOrange,
        icon: const Icon(Icons.error),
      );
    }
  }

  /// ================= FORMAT MESSAGE TIME =================
  String msgTime(String timestamp) {
    try {
      final messageTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      if (now.year == messageTime.year &&
          now.month == messageTime.month &&
          now.day == messageTime.day) {
        return DateFormat.jm().format(messageTime);
      } else if (now.difference(messageTime).inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat.yMMMd().format(messageTime);
      }
    } catch (e) {
      return '';
    }
  }
}
