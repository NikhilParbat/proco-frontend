import 'dart:convert';

SendMessage sendMessageFromJson(String str) =>
    SendMessage.fromJson(json.decode(str));

String sendMessageToJson(SendMessage data) => json.encode(data.toJson());

class SendMessage {
  SendMessage({required this.content, required this.chatId});

  factory SendMessage.fromJson(Map<String, dynamic> json) =>
      SendMessage(content: json['content'], chatId: json['chatId']);

  final String content;
  final String chatId;

  Map<String, dynamic> toJson() => {'content': content, 'chatId': chatId};
}
