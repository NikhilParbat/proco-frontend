class ReceivedMessage {
  final String id;
  final String senderId;
  final String chatId;
  final String content;
  final DateTime createdAt;
  final String messageType;
  final String? audioUrl;

  ReceivedMessage({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.content,
    required this.createdAt,
    this.messageType = 'text',
    this.audioUrl,
  });

  bool get isAudio => messageType == 'audio';

  factory ReceivedMessage.fromJson(Map<String, dynamic> json) {
    return ReceivedMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      chatId: json['chatId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      messageType: json['messageType'] ?? 'text',
      audioUrl: json['audioUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "senderId": senderId,
    "chatId": chatId,
    "content": content,
    "createdAt": createdAt.toIso8601String(),
    "messageType": messageType,
    "audioUrl": audioUrl,
  };
}
