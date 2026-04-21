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
  final bool isGroupChat;
  final String? groupAdmin;
  final String? latestMessageId;
  final List<Sender> users;
  final DateTime createdAt;
  final bool isPinned;
  final bool isUnmatched;
  final String? unmatchedBy;

  GetChats({
    required this.id,
    required this.chatName,
    required this.isGroupChat,
    required this.users,
    required this.createdAt,
    this.groupAdmin,
    this.latestMessageId,
    this.isPinned = false,
    this.isUnmatched = false,
    this.unmatchedBy,
  });

  factory GetChats.fromJson(Map<String, dynamic> json) => GetChats(
        id: json['id'] ?? '',
        chatName: json['chatName'] ?? '',
        isGroupChat: json['isGroupChat'] ?? false,
        groupAdmin: json['groupAdmin'],
        latestMessageId: json['latestMessageId'],
        users: (json['users'] as List?)
                ?.map((e) => Sender.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        isPinned: json['isPinned'] ?? false,
        isUnmatched: json['isUnmatched'] ?? false,
        unmatchedBy: json['unmatchedBy'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatName': chatName,
        'isGroupChat': isGroupChat,
        'groupAdmin': groupAdmin,
        'latestMessageId': latestMessageId,
        'users': users.map((x) => x.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isPinned': isPinned,
        'isUnmatched': isUnmatched,
        'unmatchedBy': unmatchedBy,
      };
}

class Sender {
  final String id;
  final String username;
  final String profile;

  Sender({
    required this.id,
    required this.username,
    required this.profile,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        profile: json['profile'] ?? '',
      );

  factory Sender.empty() => Sender(id: '', username: '', profile: '');

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'profile': profile,
      };
}
