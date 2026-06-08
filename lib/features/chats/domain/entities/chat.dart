import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final List<String> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatLastMessage? lastMessage;
  final Map<String, int> unread;

  const Chat({
    required this.id,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    required this.unread,
    this.lastMessage,
  });

  @override
  List<Object?> get props => [id, members, createdAt, updatedAt, lastMessage, unread];
}

class ChatLastMessage extends Equatable {
  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  const ChatLastMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, senderUid, text, createdAt];
}

