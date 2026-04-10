import 'dart:convert';

List<ReceivedMessage> receivedMessageFromJson(String str) {
  final decoded = json.decode(str);

  if (decoded['success'] != true) {
    throw Exception(decoded['message'] ?? "Failed to fetch messages");
  }

  final List data = decoded['data'] ?? [];

  return data
      .map((e) => ReceivedMessage.fromJson(e as Map<String, dynamic>))
      .toList();
}

class ReceivedMessage {
  final String id;
  final Sender sender;
  final String content;
  final String chat;
  final List<String> readBy;
  final DateTime updatedAt;
  final String messageType;
  final String? audioUrl;

  ReceivedMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.chat,
    required this.readBy,
    required this.updatedAt,
    this.messageType = 'text',
    this.audioUrl,
  });

  bool get isAudio => messageType == 'audio';

  factory ReceivedMessage.fromJson(Map<String, dynamic> json) {
    return ReceivedMessage(
      id: json['_id'] ?? '',
      sender: json['sender'] is Map<String, dynamic>
          ? Sender.fromJson(json['sender'])
          : Sender.empty(),
      content: json['content'] ?? '',
      chat: json['chat'] is String ? json['chat'] : json['chat']?['_id'] ?? '',
      readBy:
          (json['readBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      messageType: json['messageType'] ?? 'text',
      audioUrl: json['audioUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "sender": sender.toJson(),
        "content": content,
        "chat": chat,
        "readBy": readBy,
        "updatedAt": updatedAt.toIso8601String(),
        "messageType": messageType,
        "audioUrl": audioUrl,
      };
}

class Sender {
  final String id;
  final String username;
  final String email;
  final String profile;

  Sender({
    required this.id,
    required this.username,
    required this.email,
    required this.profile,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profile: json['profile'] ?? '',
    );
  }

  factory Sender.empty() {
    return Sender(
      id: '',
      username: '',
      email: '',
      profile: '',
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "username": username,
        "email": email,
        "profile": profile,
      };
}
