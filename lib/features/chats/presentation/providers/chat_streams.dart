import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/chats/domain/entities/chat.dart';
import 'package:syncly/features/chats/domain/entities/message.dart';
import 'package:syncly/features/chats/presentation/providers/chat_providers.dart';

final myChatsProvider = StreamProvider<List<Chat>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchMyChats(me.uid);
});

final chatMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

final typingProvider = StreamProvider.family<bool, ({String chatId, String otherUid})>(
  (ref, args) {
    return ref
        .watch(chatRepositoryProvider)
        .watchTyping(chatId: args.chatId, otherUid: args.otherUid);
  },
);

String _previewForMessage(Message m) {
  if (m.deletedForAll || m.text.trim().toLowerCase() == 'message deleted') {
    return 'Message deleted';
  }
  return switch (m.type) {
    MessageType.image => (m.text.trim().isEmpty ? '📷 Photo' : m.text.trim()),
    MessageType.file => '📎 ${m.fileName ?? 'File'}',
    MessageType.call => (m.text.trim().isEmpty ? 'Call' : m.text.trim()),
    MessageType.text => m.text.trim().isEmpty ? 'Message' : m.text.trim(),
  };
}

final chatSubtitleProvider =
    FutureProvider.family<String, ({String chatId, String myUid, ChatLastMessage? last})>(
        (ref, args) async {
  final last = args.last;
  if (last == null || last.id.isEmpty) return 'Tap to open';

  final repo = ref.watch(chatRepositoryProvider);
  final lastMsg = await repo.getMessageById(chatId: args.chatId, messageId: last.id);
  if (lastMsg == null) return last.text.isEmpty ? 'Tap to open' : last.text;

  // If last message is deleted for me, find the next latest visible message for me.
  if (lastMsg.deletedFor.contains(args.myUid)) {
    final recent = await repo.getRecentMessages(chatId: args.chatId, limit: 40);
    for (final m in recent) {
      if (!m.deletedFor.contains(args.myUid)) {
        return _previewForMessage(m);
      }
    }
    return 'Tap to open';
  }

  return _previewForMessage(lastMsg);
});

