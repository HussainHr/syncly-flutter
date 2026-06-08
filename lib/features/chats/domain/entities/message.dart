import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, call }

class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderUid;
  final MessageType type;
  final String text;
  final String? mediaUrl;
  final String? mediaBase64;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  // Call log message metadata (type == MessageType.call).
  final String? callType; // 'audio' | 'video'
  final String? callStatus; // 'ended' | 'rejected' | 'cancelled'
  final int? callDurationSec;

  // Chat power features metadata
  final String? replyToMessageId;
  final String? replyToSenderUid;
  final String? replyToText;
  final String? replyToType; // 'text' | 'image' | 'file' | 'call'

  final bool isForwarded;
  final String? forwardedFromUid;

  final List<String> starredBy; // UIDs who starred this message

  // Delete controls
  final bool deletedForAll;
  final List<String> deletedFor; // UIDs for "delete for me"
  final String? deletedBy; // UID who deleted for all
  final DateTime? deletedAt;
  final DateTime createdAt;
  final List<String> deliveredTo;
  final List<String> readBy;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderUid,
    required this.type,
    required this.text,
    this.mediaUrl,
    this.mediaBase64,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.width,
    this.height,
    this.callType,
    this.callStatus,
    this.callDurationSec,
    this.replyToMessageId,
    this.replyToSenderUid,
    this.replyToText,
    this.replyToType,
    this.isForwarded = false,
    this.forwardedFromUid,
    this.starredBy = const <String>[],
    this.deletedForAll = false,
    this.deletedFor = const <String>[],
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    required this.deliveredTo,
    required this.readBy,
  });

  @override
  List<Object?> get props =>
      [
        id,
        chatId,
        senderUid,
        type,
        text,
        mediaUrl,
        mediaBase64,
        fileName,
        mimeType,
        sizeBytes,
        width,
        height,
        callType,
        callStatus,
        callDurationSec,
        replyToMessageId,
        replyToSenderUid,
        replyToText,
        replyToType,
        isForwarded,
        forwardedFromUid,
        starredBy,
        deletedForAll,
        deletedFor,
        deletedBy,
        deletedAt,
        createdAt,
        deliveredTo,
        readBy,
      ];
}

