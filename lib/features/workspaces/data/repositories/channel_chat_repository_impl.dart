import '../../../chats/domain/entities/message.dart';
import '../../domain/repositories/channel_chat_repository.dart';
import '../datasources/channel_messages_remote_data_source.dart';

class ChannelChatRepositoryImpl implements ChannelChatRepository {
  final ChannelMessagesRemoteDataSource _remote;

  ChannelChatRepositoryImpl(this._remote);

  @override
  Stream<List<Message>> watchMessages({
    required String workspaceId,
    required String channelId,
    int limit = 50,
  }) =>
      _remote.watchMessages(
        workspaceId: workspaceId,
        channelId: channelId,
        limit: limit,
      );

  @override
  Future<void> sendTextMessage({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required String text,
    String? messageId,
  }) =>
      _remote.sendTextMessage(
        workspaceId: workspaceId,
        channelId: channelId,
        myUid: myUid,
        text: text,
        messageId: messageId,
      );

  @override
  Future<void> sendImageMessage({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required String imageBase64,
    String? caption,
    required int sizeBytes,
  }) =>
      _remote.sendImageMessage(
        workspaceId: workspaceId,
        channelId: channelId,
        myUid: myUid,
        imageBase64: imageBase64,
        caption: caption,
        sizeBytes: sizeBytes,
      );

  @override
  Future<void> markChannelRead({
    required String workspaceId,
    required String channelId,
    required String myUid,
    bool sendReadReceipts = true,
  }) =>
      _remote.markChannelRead(
        workspaceId: workspaceId,
        channelId: channelId,
        myUid: myUid,
        sendReadReceipts: sendReadReceipts,
      );

  @override
  Future<void> setTyping({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required bool isTyping,
  }) =>
      _remote.setTyping(
        workspaceId: workspaceId,
        channelId: channelId,
        myUid: myUid,
        isTyping: isTyping,
      );

  @override
  Stream<List<String>> watchTypingMemberUids({
    required String workspaceId,
    required String channelId,
    required String myUid,
  }) =>
      _remote.watchTypingMemberUids(
        workspaceId: workspaceId,
        channelId: channelId,
        myUid: myUid,
      );
}
