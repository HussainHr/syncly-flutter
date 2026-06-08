import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;

  ChatRepositoryImpl(this._remote);

  @override
  Stream<List<Chat>> watchMyChats(String myUid) => _remote.watchMyChats(myUid);

  @override
  Stream<List<Message>> watchMessages(String chatId, {int limit = 50}) =>
      _remote.watchMessages(chatId, limit: limit);

  @override
  Future<Chat> createOrGetDirectChat({
    required String myUid,
    required String otherUid,
  }) =>
      _remote.createOrGetDirectChat(myUid: myUid, otherUid: otherUid);

  @override
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
  }) =>
      _remote.sendTextMessage(
        chatId: chatId,
        myUid: myUid,
        text: text,
        messageId: messageId,
        replyToMessageId: replyToMessageId,
        replyToSenderUid: replyToSenderUid,
        replyToText: replyToText,
        replyToType: replyToType,
        isForwarded: isForwarded,
        forwardedFromUid: forwardedFromUid,
      );

  @override
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
  }) =>
      _remote.sendImageMessage(
        chatId: chatId,
        myUid: myUid,
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        caption: caption,
        sizeBytes: sizeBytes,
        width: width,
        height: height,
        replyToMessageId: replyToMessageId,
        replyToSenderUid: replyToSenderUid,
        replyToText: replyToText,
        replyToType: replyToType,
        isForwarded: isForwarded,
        forwardedFromUid: forwardedFromUid,
      );

  @override
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
  }) =>
      _remote.sendFileMessage(
        chatId: chatId,
        myUid: myUid,
        fileUrl: fileUrl,
        fileBase64: fileBase64,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        replyToMessageId: replyToMessageId,
        replyToSenderUid: replyToSenderUid,
        replyToText: replyToText,
        replyToType: replyToType,
        isForwarded: isForwarded,
        forwardedFromUid: forwardedFromUid,
      );

  @override
  Future<void> markChatRead({
    required String chatId,
    required String myUid,
    bool sendReadReceipts = true,
  }) =>
      _remote.markChatRead(
        chatId: chatId,
        myUid: myUid,
        sendReadReceipts: sendReadReceipts,
      );

  @override
  Future<void> setTyping({
    required String chatId,
    required String myUid,
    required bool isTyping,
  }) =>
      _remote.setTyping(chatId: chatId, myUid: myUid, isTyping: isTyping);

  @override
  Stream<bool> watchTyping({
    required String chatId,
    required String otherUid,
  }) =>
      _remote.watchTyping(chatId: chatId, otherUid: otherUid);

  @override
  Future<Message?> getMessageById({
    required String chatId,
    required String messageId,
  }) =>
      _remote.getMessageById(chatId: chatId, messageId: messageId);

  @override
  Future<List<Message>> getRecentMessages({
    required String chatId,
    int limit = 30,
  }) =>
      _remote.getRecentMessages(chatId: chatId, limit: limit);

  @override
  Future<void> setStarred({
    required String chatId,
    required String messageId,
    required String myUid,
    required bool starred,
  }) =>
      _remote.setStarred(
        chatId: chatId,
        messageId: messageId,
        myUid: myUid,
        starred: starred,
      );

  @override
  Future<void> deleteForMe({
    required String chatId,
    required String messageId,
    required String myUid,
  }) =>
      _remote.deleteForMe(
        chatId: chatId,
        messageId: messageId,
        myUid: myUid,
      );

  @override
  Future<void> deleteForEveryone({
    required String chatId,
    required String messageId,
    required String myUid,
  }) =>
      _remote.deleteForEveryone(
        chatId: chatId,
        messageId: messageId,
        myUid: myUid,
      );
}

