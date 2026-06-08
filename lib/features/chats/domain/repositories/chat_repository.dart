import '../entities/chat.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Stream<List<Chat>> watchMyChats(String myUid);
  Stream<List<Message>> watchMessages(String chatId, {int limit = 50});

  Future<Chat> createOrGetDirectChat({
    required String myUid,
    required String otherUid,
  });

  Future<void> sendTextMessage({
    required String chatId,
    required String myUid,
    required String text,
    String? messageId,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  });

  Future<void> sendImageMessage({
    required String chatId,
    required String myUid,
    String? imageUrl,
    String? imageBase64,
    String? caption,
    required int? sizeBytes,
    required int? width,
    required int? height,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  });

  Future<void> sendFileMessage({
    required String chatId,
    required String myUid,
    String? fileUrl,
    String? fileBase64,
    required String fileName,
    required String? mimeType,
    required int? sizeBytes,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  });

  Future<void> markChatRead({
    required String chatId,
    required String myUid,
    bool sendReadReceipts = true,
  });

  Future<void> setTyping({
    required String chatId,
    required String myUid,
    required bool isTyping,
  });

  Stream<bool> watchTyping({
    required String chatId,
    required String otherUid,
  });

  Future<Message?> getMessageById({
    required String chatId,
    required String messageId,
  });

  Future<List<Message>> getRecentMessages({
    required String chatId,
    int limit = 30,
  });

  Future<void> setStarred({
    required String chatId,
    required String messageId,
    required String myUid,
    required bool starred,
  });

  Future<void> deleteForMe({
    required String chatId,
    required String messageId,
    required String myUid,
  });

  Future<void> deleteForEveryone({
    required String chatId,
    required String messageId,
    required String myUid,
  });
}

