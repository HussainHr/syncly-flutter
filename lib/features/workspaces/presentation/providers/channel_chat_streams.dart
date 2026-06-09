import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';

import '../../../chats/domain/entities/message.dart';
import 'channel_chat_providers.dart';

typedef ChannelRef = ({String workspaceId, String channelId});

final channelMessagesProvider =
    StreamProvider.family<List<Message>, ChannelRef>((ref, args) {
  return ref.watch(channelChatRepositoryProvider).watchMessages(
        workspaceId: args.workspaceId,
        channelId: args.channelId,
      );
});

final channelTypingMembersProvider =
    StreamProvider.family<List<String>, ChannelRef>((ref, args) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream<List<String>>.empty();
  return ref.watch(channelChatRepositoryProvider).watchTypingMemberUids(
        workspaceId: args.workspaceId,
        channelId: args.channelId,
        myUid: me.uid,
      );
});
