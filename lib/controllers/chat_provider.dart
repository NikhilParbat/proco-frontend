import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proco/controllers/loading_mixin.dart';
import 'package:proco/models/request/chat/create_chat.dart';
import 'package:proco/models/response/chat/get_chat.dart';
import 'package:proco/services/helpers/chat_helper.dart';
import 'package:proco/views/common/lagoon_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatNotifier extends ChangeNotifier with LoadingMixin {
  List<GetChats> chats = [];

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

  final Map<String, bool> _localPinOverride = {};

  bool isPinned(String chatId) => _localPinOverride[chatId] ?? false;

  String _chatCacheKey(String uid) => 'chat_cache_$uid';

  // ─── Cache ────────────────────────────────────────────────────────────────

  Future<void> _loadChatsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? '';
    if (uid.isEmpty) return;
    final raw = prefs.getString(_chatCacheKey(uid));
    if (raw == null || raw.isEmpty) return;
    try {
      final cached = getChatsFromJson(raw);
      chats = cached;
      for (final c in chats) {
        _localPinOverride[c.id] = c.isPinned;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveChatsToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? '';
    if (uid.isEmpty) return;
    await prefs.setString(_chatCacheKey(uid), getChatsToJson(chats));
  }

  // ─── Get chats ────────────────────────────────────────────────────────────

  Future<void> getChats() async {
    await runWithLoading(() async {
      await _loadChatsFromCache();
      final response = await ChatHelper.getConversations();
      if (response.success && response.data != null) {
        chats = response.data!;
        for (final c in chats) {
          _localPinOverride[c.id] = c.isPinned;
        }
        await _saveChatsToCache();
      } else {
        LagoonSnackbar.show(
          title: 'Failed to load chats',
          message: response.message,
          isError: true,
        );
      }
    });
  }

  // ─── Create / access chat ─────────────────────────────────────────────────

  Future<String?> createChat(CreateChat model) async {
    final response = await ChatHelper.createChat(model);
    if (response.success && response.data != null) {
      return response.data;
    }
    LagoonSnackbar.show(
      title: 'Could not open chat',
      message: response.message,
      isError: true,
    );
    return null;
  }

  // ─── Get user ID ──────────────────────────────────────────────────────────

  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    notifyListeners();
  }

  // ─── Toggle pin ───────────────────────────────────────────────────────────

  Future<void> togglePin(String chatId) async {
    final current = _localPinOverride[chatId] ?? false;
    _localPinOverride[chatId] = !current;
    notifyListeners();

    final response = await ChatHelper.togglePin(chatId);
    if (response.success && response.data != null) {
      _localPinOverride[chatId] = response.data!;
    } else {
      _localPinOverride[chatId] = current;
      LagoonSnackbar.show(
        title: 'Pin failed',
        message: response.message,
        isError: true,
      );
    }
    notifyListeners();
  }

  // ─── Unmatch ──────────────────────────────────────────────────────────────

  Future<void> unmatchChat(String chatId) async {
    final backup = List<GetChats>.from(chats);
    chats = chats.where((c) => c.id != chatId).toList();
    _localPinOverride.remove(chatId);
    notifyListeners();

    final response = await ChatHelper.unmatchChat(chatId);
    if (!response.success) {
      chats = backup;
      notifyListeners();
      LagoonSnackbar.show(
        title: 'Unmatch failed',
        message: response.message,
        isError: true,
      );
    }
  }

  // ─── Clear chat ───────────────────────────────────────────────────────────

  Future<void> clearChat(String chatId) async {
    final response = await ChatHelper.clearChat(chatId);
    if (!response.success) {
      LagoonSnackbar.show(
        title: 'Could not clear chat',
        message: response.message,
        isError: true,
      );
    }
  }

  // ─── Format message time ──────────────────────────────────────────────────

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
