import 'package:flutter/material.dart';
import 'package:proco/models/request/messaging/send_message.dart';
import 'package:proco/models/response/messaging/messaging_res.dart';
import 'package:proco/services/helpers/messaging_helper.dart';
import 'package:proco/views/common/lagoon_snackbar.dart';

class MessageNotifier extends ChangeNotifier {
  final Map<String, List<ReceivedMessage>> _messagesByChatId = {};
  final Map<String, bool> _isLoadingByChatId = {};
  final Map<String, bool> _hasMoreByChatId = {};
  final Map<String, int> _offsetByChatId = {};
  String? currentUserId;

  bool _isSending = false;
  bool get isSending => _isSending;

  List<ReceivedMessage> messagesFor(String chatId) =>
      _messagesByChatId[chatId] ?? [];

  bool isLoadingFor(String chatId) => _isLoadingByChatId[chatId] ?? false;

  bool hasMoreFor(String chatId) => _hasMoreByChatId[chatId] ?? true;

  // ─── Fetch messages (paginated) ───────────────────────────────────────────

  Future<void> getMessages(String chatId, {bool refresh = false}) async {
    if (isLoadingFor(chatId)) return;
    if (!hasMoreFor(chatId) && !refresh) return;

    if (refresh) {
      _offsetByChatId[chatId] = 0;
      _hasMoreByChatId[chatId] = true;
      _messagesByChatId[chatId] = [];
    }

    _isLoadingByChatId[chatId] = true;
    notifyListeners();

    try {
      final offset = _offsetByChatId[chatId] ?? 0;
      final fetched = await MesssagingHelper.getMessages(chatId, offset);

      final existing = _messagesByChatId[chatId] ?? [];

      if (fetched.isEmpty) {
        _hasMoreByChatId[chatId] = false;
      } else {
        _messagesByChatId[chatId] = [...existing, ...fetched];
        _offsetByChatId[chatId] = offset + 1;
      }
    } catch (e) {
      LagoonSnackbar.show(
        title: 'Failed to load messages',
        message: e.toString(),
        isError: true,
      );
    }

    _isLoadingByChatId[chatId] = false;
    notifyListeners();
  }

  // ─── Send message ─────────────────────────────────────────────────────────

  Future<ReceivedMessage?> sendMessage(SendMessage model) async {
    _isSending = true;

    // Optimistic update: insert a temporary message immediately so the UI
    // updates before the API responds.
    final chatId = model.chatId;
    final optimisticMsg = ReceivedMessage.optimistic(
      content: model.content,
      chatId: chatId,
      senderId: currentUserId ?? '',
    );
    _messagesByChatId[chatId] = [
      optimisticMsg,
      ...(_messagesByChatId[chatId] ?? []),
    ];
    notifyListeners();

    final result = await MesssagingHelper.sendMessage(model);

    _isSending = false;

    if (result['success'] == true && result['message'] is ReceivedMessage) {
      final message = result['message'] as ReceivedMessage;

      // Replace the optimistic message with the real one from the server.
      final list = _messagesByChatId[chatId] ?? [];
      final idx = list.indexWhere((m) => m.id == optimisticMsg.id);
      if (idx != -1) {
        list[idx] = message;
        _messagesByChatId[chatId] = List.from(list);
      } else {
        _messagesByChatId[chatId] = [message, ...list];
      }

      notifyListeners();
      return message;
    } else {
      // Roll back the optimistic message on failure.
      final list = _messagesByChatId[chatId] ?? [];
      _messagesByChatId[chatId] = list
          .where((m) => m.id != optimisticMsg.id)
          .toList();

      LagoonSnackbar.show(
        title: 'Failed to send',
        message: result['message']?.toString() ?? 'Something went wrong',
        isError: true,
      );
      notifyListeners();
      return null;
    }
  }

  // ─── Add incoming socket message ──────────────────────────────────────────

  void addIncomingMessage(String chatId, ReceivedMessage message) {
    final list = _messagesByChatId[chatId] ?? [];
    // Ignore if we already have this message id (e.g. our own optimistic was replaced)
    if (list.any((m) => m.id == message.id)) return;
    _messagesByChatId[chatId] = [message, ...list];
    notifyListeners();
  }

  // ─── Clear messages for a chat (on unmatch/clear) ─────────────────────────

  void clearChat(String chatId) {
    _messagesByChatId.remove(chatId);
    _offsetByChatId.remove(chatId);
    _hasMoreByChatId.remove(chatId);
    _isLoadingByChatId.remove(chatId);
    notifyListeners();
  }

  // ─── Clear all (on logout) ────────────────────────────────────────────────

  void clearAll() {
    _messagesByChatId.clear();
    _offsetByChatId.clear();
    _hasMoreByChatId.clear();
    _isLoadingByChatId.clear();
    _isSending = false;
    notifyListeners();
  }
}
