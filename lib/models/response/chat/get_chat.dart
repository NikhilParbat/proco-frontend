import 'dart:convert';

List<GetChats> getChatsFromJson(String str) {
  final decoded = json.decode(str);
  final List data = (decoded is Map && decoded.containsKey('data'))
      ? decoded['data'] as List
      : decoded as List;
  return data.map((e) => GetChats.fromJson(e as Map<String, dynamic>)).toList();
}

String getChatsToJson(List<GetChats> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetChats {
  final String id;
  final String chatName;
  final String? latestMessageId;
  final String? latestMessage;
  final List<Sender> users;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isUnmatched;
  final String? unmatchedBy;

  GetChats({
    required this.id,
    required this.chatName,
    required this.users,
    required this.createdAt,
    required this.updatedAt,
    this.latestMessageId,
    this.latestMessage,
    this.isPinned = false,
    this.isUnmatched = false,
    this.unmatchedBy,
  });

  factory GetChats.fromJson(Map<String, dynamic> json) => GetChats(
    id: json['id'] ?? '',
    chatName: json['chatName'] ?? '',
    latestMessageId: json['latestMessageId'],
    latestMessage: json['latestMessage'] as String?,
    users:
        (json['users'] as List?)
            ?.map((e) => Sender.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
    isPinned: json['isPinned'] ?? false,
    isUnmatched: json['isUnmatched'] ?? false,
    unmatchedBy: json['unmatchedBy'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatName': chatName,
    'latestMessageId': latestMessageId,
    'latestMessage': latestMessage,
    'users': users.map((x) => x.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isPinned': isPinned,
    'isUnmatched': isUnmatched,
    'unmatchedBy': unmatchedBy,
  };
}

class Sender {
  final String id;
  final String username;
  final String profile;
  final String? lastMessage;

  Sender({
    required this.id,
    required this.username,
    required this.profile,
    this.lastMessage,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    profile: json['profile'] ?? '',
    lastMessage: json['lastMessage'] ?? '',
  );

  factory Sender.empty() =>
      Sender(id: '', username: '', profile: '', lastMessage: '');

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'profile': profile,
    'lastMessage': lastMessage,
  };
}
