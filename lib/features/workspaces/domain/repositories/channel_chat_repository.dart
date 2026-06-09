import '../../../chats/domain/entities/message.dart';

abstract class ChannelChatRepository {
  Stream<List<Message>> watchMessages({
    required String workspaceId,
    required String channelId,
    int limit = 50,
  });

  Future<void> sendTextMessage({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required String text,
    String? messageId,
  });

  Future<void> sendImageMessage({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required String imageBase64,
    String? caption,
    required int sizeBytes,
  });

  Future<void> markChannelRead({
    required String workspaceId,
    required String channelId,
    required String myUid,
    bool sendReadReceipts = true,
  });

  Future<void> setTyping({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required bool isTyping,
  });

  Stream<List<String>> watchTypingMemberUids({
    required String workspaceId,
    required String channelId,
    required String myUid,
  });
}
