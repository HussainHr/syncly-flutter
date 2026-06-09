import 'package:equatable/equatable.dart';

enum ChannelType { text }

class ChannelLastMessage extends Equatable {
  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  const ChannelLastMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, senderUid, text, createdAt];
}

class Channel extends Equatable {
  final String id;
  final String workspaceId;
  final String name;
  final ChannelType type;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChannelLastMessage? lastMessage;
  final Map<String, int> unread;

  const Channel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unread = const <String, int>{},
  });

  String get displayName => name.startsWith('#') ? name : '#$name';

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        name,
        type,
        createdBy,
        createdAt,
        updatedAt,
        lastMessage,
        unread,
      ];

  int unreadFor(String uid) => unread[uid] ?? 0;
}
