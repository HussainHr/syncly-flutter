import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/channel.dart';

class ChannelModel extends Channel {
  const ChannelModel({
    required super.id,
    required super.workspaceId,
    required super.name,
    required super.type,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.lastMessage,
    super.unread,
  });

  static DateTime _readDate(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    return fallback ?? DateTime.now();
  }

  static ChannelType _typeFromString(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'text' => ChannelType.text,
      _ => ChannelType.text,
    };
  }

  static ChannelLastMessage? _lastMessageFromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    final id = (map['id'] as String?) ?? '';
    if (id.isEmpty) return null;
    return ChannelLastMessage(
      id: id,
      senderUid: (map['senderUid'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      createdAt: _readDate(map['createdAt']),
    );
  }

  factory ChannelModel.fromDoc({
    required String workspaceId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = _readDate(data['createdAt']);
    final lastMap = data['lastMessage'] as Map<String, dynamic>?;
    return ChannelModel(
      id: doc.id,
      workspaceId: workspaceId,
      name: (data['name'] as String?) ?? 'general',
      type: _typeFromString(data['type'] as String?),
      createdBy: (data['createdBy'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: _readDate(data['updatedAt'], fallback: createdAt),
      lastMessage: _lastMessageFromMap(lastMap),
      unread: _unreadFromMap(data['unread'] as Map<String, dynamic>?),
    );
  }

  static Map<String, int> _unreadFromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const <String, int>{};
    return map.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
  }
}
