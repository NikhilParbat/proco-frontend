import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proco/models/response/chat/get_chat.dart';
import 'package:proco/services/helpers/chat_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatNotifier extends ChangeNotifier {
  Future<List<GetChats>>? chats;

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

  bool isPinned(String chatId) {
    // Derived from the server response stored in the chats future
    return _localPinOverride[chatId] ?? false;
  }

  // Optimistic local pin state while API call is in flight
  final Map<String, bool> _localPinOverride = {};

  /// ================= LOAD CHATS =================
  Future<void> getChats() async {
    try {
      chats = ChatHelper.getConversations().then((list) {
        for (final c in list) {
          _localPinOverride[c.id] = c.isPinned;
        }
        return list;
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Chat Fetch Error: $e");
    }
  }

  /// ================= GET USER ID =================
  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    notifyListeners();
  }

  /// ================= TOGGLE PIN =================
  Future<void> togglePin(String chatId) async {
    // Optimistic update
    final current = _localPinOverride[chatId] ?? false;
    _localPinOverride[chatId] = !current;
    notifyListeners();

    final result = await ChatHelper.togglePin(chatId);
    if (result != null) {
      _localPinOverride[chatId] = result;
    } else {
      // Revert on failure
      _localPinOverride[chatId] = current;
    }
    notifyListeners();
  }

  /// ================= UNMATCH (removes chat from initiator's view) =================
  Future<void> unmatchChat(String chatId) async {
    chats = chats?.then((list) => list.where((c) => c.id != chatId).toList());
    _localPinOverride.remove(chatId);
    notifyListeners();
    await ChatHelper.unmatchChat(chatId);
  }

  /// ================= CLEAR CHAT (deletes all messages) =================
  Future<void> clearChat(String chatId) async {
    await ChatHelper.clearChat(chatId);
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
