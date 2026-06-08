import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat.dart';

class ChatModel extends Chat {
  const ChatModel({
    required super.id,
    required super.members,
    required super.createdAt,
    required super.updatedAt,
    required super.unread,
    super.lastMessage,
  });

  static DateTime _readDate(dynamic v, {DateTime? fallback}) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return fallback ?? DateTime.now();
  }

  factory ChatModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final members = (data['members'] as List?)?.cast<String>() ?? const <String>[];
    final createdAt = _readDate(data['createdAt']);
    final updatedAt = _readDate(data['updatedAt'], fallback: createdAt);

    ChatLastMessage? last;
    final lm = data['lastMessage'];
    if (lm is Map<String, dynamic>) {
      last = ChatLastMessage(
        id: (lm['id'] as String?) ?? '',
        senderUid: (lm['senderUid'] as String?) ?? '',
        text: (lm['text'] as String?) ?? '',
        createdAt: _readDate(lm['createdAt'], fallback: updatedAt),
      );
    }

    final unreadMap = <String, int>{};
    final u = data['unread'];
    if (u is Map) {
      for (final e in u.entries) {
        final k = e.key?.toString();
        if (k == null) continue;
        unreadMap[k] = (e.value as num?)?.toInt() ?? 0;
      }
    }

    return ChatModel(
      id: doc.id,
      members: members,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessage: last,
      unread: unreadMap,
    );
  }
}

