import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderUid,
    required super.type,
    required super.text,
    super.mediaUrl,
    super.mediaBase64,
    super.fileName,
    super.mimeType,
    super.sizeBytes,
    super.width,
    super.height,
    super.callType,
    super.callStatus,
    super.callDurationSec,
    super.replyToMessageId,
    super.replyToSenderUid,
    super.replyToText,
    super.replyToType,
    super.isForwarded,
    super.forwardedFromUid,
    super.starredBy,
    super.deletedForAll,
    super.deletedFor,
    super.deletedBy,
    super.deletedAt,
    required super.createdAt,
    required super.deliveredTo,
    required super.readBy,
  });

  static DateTime _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static MessageType _typeFromString(String? v) {
    return switch ((v ?? '').toLowerCase()) {
      'image' => MessageType.image,
      'file' => MessageType.file,
      'call' => MessageType.call,
      _ => MessageType.text,
    };
  }

  factory MessageModel.fromDoc(
      String chatId,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return MessageModel(
      id: doc.id,
      chatId: chatId,
      senderUid: (data['senderUid'] as String?) ?? '',
      type: _typeFromString(data['type'] as String?),
      text: (data['text'] as String?) ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaBase64: data['mediaBase64'] as String?,
      fileName: data['fileName'] as String?,
      mimeType: data['mimeType'] as String?,
      sizeBytes: (data['sizeBytes'] as num?)?.toInt(),
      width: (data['width'] as num?)?.toInt(),
      height: (data['height'] as num?)?.toInt(),
      callType: data['callType'] as String?,
      callStatus: data['callStatus'] as String?,
      callDurationSec: (data['callDurationSec'] as num?)?.toInt(),
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToSenderUid: data['replyToSenderUid'] as String?,
      replyToText: data['replyToText'] as String?,
      replyToType: data['replyToType'] as String?,
      isForwarded: (data['isForwarded'] as bool?) ?? false,
      forwardedFromUid: data['forwardedFromUid'] as String?,
      starredBy: (data['starredBy'] as List?)?.cast<String>() ?? const <String>[],
      deletedForAll: (data['deletedForAll'] as bool?) ?? false,
      deletedFor: (data['deletedFor'] as List?)?.cast<String>() ?? const <String>[],
      deletedBy: data['deletedBy'] as String?,
      deletedAt: data['deletedAt'] == null ? null : _readDate(data['deletedAt']),
      createdAt: _readDate(data['createdAt']),
      deliveredTo: (data['deliveredTo'] as List?)?.cast<String>() ?? const <String>[],
      readBy: (data['readBy'] as List?)?.cast<String>() ?? const <String>[],
    );
  }
}

