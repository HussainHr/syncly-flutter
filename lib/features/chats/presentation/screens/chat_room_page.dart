import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/chats/domain/entities/message.dart';
import 'package:syncly/features/chats/presentation/providers/chat_providers.dart';
import 'package:syncly/features/chats/presentation/providers/chat_streams.dart';
import 'package:syncly/features/attachments/presentation/providers/attachment_send_controller.dart';
import 'package:syncly/features/attachments/presentation/utils/file_download_and_open.dart';
import 'package:syncly/features/chats/presentation/widgets/pending_image_preview.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/core/widgets/skeletons/chat_bubble_skeleton.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/utils/privacy.dart';
import 'package:syncly/features/friends/presentation/providers/relationship_provider.dart';
import 'package:syncly/features/friends/presentation/providers/friends_streams.dart';
import 'package:syncly/features/chats/domain/entities/chat.dart';
import 'package:syncly/core/utils/toast_message.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUid;

  const ChatRoomPage({super.key, required this.chatId, required this.otherUid});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _controller = TextEditingController();
  Timer? _typingDebounce;
  XFile? _pendingImage;
  PlatformFile? _pendingFile;
  Message? _replyTo;
  final List<Message> _pendingLocal = <Message>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = ref.read(currentUserProvider);
      if (me != null) {
        final myProfile = ref.read(userProfileProvider(me.uid)).valueOrNull;
        ref.read(chatRepositoryProvider).markChatRead(
              chatId: widget.chatId,
              myUid: me.uid,
              sendReadReceipts: myProfile?.readReceiptsEnabled ?? true,
            );
      }
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setTyping(bool v) {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final myProfile = ref.read(userProfileProvider(me.uid)).valueOrNull;
    if (myProfile?.typingIndicatorEnabled == false) return;
    ref.read(chatRepositoryProvider).setTyping(chatId: widget.chatId, myUid: me.uid, isTyping: v);
  }

  Future<void> _send() async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final text = _controller.text;
    _controller.clear();
    _setTyping(false);

    final reply = _replyTo;
    setState(() => _replyTo = null);

    if (_pendingImage != null) {
      final path = _pendingImage!.path;
      setState(() => _pendingImage = null);
      await ref.read(attachmentSendControllerProvider.notifier).sendImage(
            chatId: widget.chatId,
            filePath: path,
            caption: text.trim().isEmpty ? null : text.trim(),
            replyToMessageId: reply?.id,
            replyToSenderUid: reply?.senderUid,
            replyToText: (reply?.text ?? '').trim().isEmpty ? null : reply!.text.trim(),
            replyToType: reply == null ? null : reply.type.name,
          );
      return;
    }

    if (_pendingFile != null) {
      final f = _pendingFile!;
      final path = f.path;
      setState(() => _pendingFile = null);
      if (path == null) return;

      final ext = (f.extension ?? '').toLowerCase();
      final mimeType = switch (ext) {
        'pdf' => 'application/pdf',
        'txt' => 'text/plain',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'mp4' => 'video/mp4',
        'mp3' => 'audio/mpeg',
        _ => null,
      };

      await ref.read(attachmentSendControllerProvider.notifier).sendFile(
            chatId: widget.chatId,
            filePath: path,
            fileName: f.name,
            sizeBytes: f.size,
            mimeType: mimeType,
            replyToMessageId: reply?.id,
            replyToSenderUid: reply?.senderUid,
            replyToText: (reply?.text ?? '').trim().isEmpty ? null : reply!.text.trim(),
            replyToType: reply == null ? null : reply.type.name,
          );

      if (text.trim().isNotEmpty) {
        await ref.read(chatRepositoryProvider).sendTextMessage(
              chatId: widget.chatId,
              myUid: me.uid,
              text: text.trim(),
              replyToMessageId: reply?.id,
              replyToSenderUid: reply?.senderUid,
              replyToText: (reply?.text ?? '').trim().isEmpty ? null : reply!.text.trim(),
              replyToType: reply == null ? null : reply.type.name,
            );
      }
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Optimistic UI: generate id, show immediately, then write using same id.
    final localId = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc()
        .id;

    final localMsg = Message(
      id: localId,
      chatId: widget.chatId,
      senderUid: me.uid,
      type: MessageType.text,
      text: trimmed,
      createdAt: DateTime.now(),
      deliveredTo: [me.uid],
      readBy: [me.uid],
      replyToMessageId: reply?.id,
      replyToSenderUid: reply?.senderUid,
      replyToText: (reply?.text ?? '').trim().isEmpty ? null : reply!.text.trim(),
      replyToType: reply == null ? null : reply.type.name,
    );

    setState(() => _pendingLocal.insert(0, localMsg));

    try {
      await ref.read(chatRepositoryProvider).sendTextMessage(
            chatId: widget.chatId,
            myUid: me.uid,
            text: trimmed,
            messageId: localId,
            replyToMessageId: reply?.id,
            replyToSenderUid: reply?.senderUid,
            replyToText: (reply?.text ?? '').trim().isEmpty ? null : reply!.text.trim(),
            replyToType: reply == null ? null : reply.type.name,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingLocal.removeWhere((m) => m.id == localId));
      showToast('Send failed: $e');
    }
  }

  Future<void> _forwardMessage({required Message message}) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    if (message.type == MessageType.call) return;

    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ForwardToSheet(myUid: me.uid),
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    for (final uid in selected) {
      final chat = await ref.read(chatRepositoryProvider).createOrGetDirectChat(
            myUid: me.uid,
            otherUid: uid,
          );

      switch (message.type) {
        case MessageType.text:
          await ref.read(chatRepositoryProvider).sendTextMessage(
                chatId: chat.id,
                myUid: me.uid,
                text: message.text,
                isForwarded: true,
                forwardedFromUid: message.senderUid,
              );
          break;
        case MessageType.image:
          await ref.read(chatRepositoryProvider).sendImageMessage(
                chatId: chat.id,
                myUid: me.uid,
                imageUrl: message.mediaUrl,
                imageBase64: message.mediaBase64,
                caption: message.text.trim().isEmpty ? null : message.text.trim(),
                sizeBytes: message.sizeBytes,
                width: message.width,
                height: message.height,
                isForwarded: true,
                forwardedFromUid: message.senderUid,
              );
          break;
        case MessageType.file:
          await ref.read(chatRepositoryProvider).sendFileMessage(
                chatId: chat.id,
                myUid: me.uid,
                fileUrl: message.mediaUrl,
                fileBase64: message.mediaBase64,
                fileName: message.fileName ?? 'File',
                mimeType: message.mimeType,
                sizeBytes: message.sizeBytes,
                isForwarded: true,
                forwardedFromUid: message.senderUid,
              );
          break;
        case MessageType.call:
          break;
      }
    }

    if (!mounted) return;
    showToast('Forwarded to ${selected.length} chat(s)');
  }

  Future<void> _toggleStar(Message m) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final starred = m.starredBy.contains(me.uid);
    await ref.read(chatRepositoryProvider).setStarred(
          chatId: widget.chatId,
          messageId: m.id,
          myUid: me.uid,
          starred: !starred,
        );
    showToast(!starred ? 'Starred' : 'Unstarred');
  }

  Future<void> _deleteMessageForMe(Message m) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    await ref.read(chatRepositoryProvider).deleteForMe(
          chatId: widget.chatId,
          messageId: m.id,
          myUid: me.uid,
        );
    showToast('Deleted for you');
  }

  Future<void> _deleteMessageForEveryone(Message m) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    await ref.read(chatRepositoryProvider).deleteForEveryone(
          chatId: widget.chatId,
          messageId: m.id,
          myUid: me.uid,
        );
    showToast('Deleted for everyone');
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 2048);
    if (x == null) return;
    setState(() => _pendingImage = x);
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(withReadStream: false);
    final f = result?.files.single;
    if (f == null) return;
    final path = f.path;
    if (path == null) return;
    setState(() => _pendingFile = f);
  }

  Future<void> _showAttachSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Photo'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _pickAndSendFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final other = ref.watch(userProfileProvider(widget.otherUid)).valueOrNull;
    final relationship = ref.watch(relationshipProvider(widget.otherUid));
    final typing = ref.watch(typingProvider((chatId: widget.chatId, otherUid: widget.otherUid)));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final attachState = ref.watch(attachmentSendControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: other == null ? null : () => context.push('/users/${other.uid}'),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: other == null
                      ? null
                      : () => showAvatarViewer(
                            context,
                            name: other.displayName,
                            photoUrl: other.photoUrl,
                            photoBase64: other.photoBase64,
                          ),
                  child: CustomAvatar(
                    height: 36,
                    width: 36,
                    name: other?.displayName ?? '',
                    image: (other == null ||
                            me == null ||
                            !canSeeByAudience(
                              audience: other.privacyPhoto,
                              isMe: me.uid == other.uid,
                              relationship: relationship,
                            ))
                        ? ''
                        : (other.photoUrl ?? ''),
                    base64: (other == null ||
                            me == null ||
                            !canSeeByAudience(
                              audience: other.privacyPhoto,
                              isMe: me.uid == other.uid,
                              relationship: relationship,
                            ))
                        ? null
                        : other.photoBase64,
                    network: other != null &&
                        me != null &&
                        canSeeByAudience(
                          audience: other.privacyPhoto,
                          isMe: me.uid == other.uid,
                          relationship: relationship,
                        ) &&
                        (other.photoUrl ?? '').isNotEmpty,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        other?.displayName ?? 'Chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      typing.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (isTyping) {
                          if (other == null || me == null) {
                            return const SizedBox.shrink();
                          }

                          final canSeeOnline = canSeeByAudience(
                            audience: other.privacyOnline,
                            isMe: me.uid == other.uid,
                            relationship: relationship,
                          );

                          final showTyping =
                              other.typingIndicatorEnabled && (isTyping == true);
                          final text = showTyping
                              ? 'typing…'
                              : (canSeeOnline && other.isOnline == true ? 'online' : '');
                          if (text.isEmpty) return const SizedBox.shrink();
                          final cs = Theme.of(context).colorScheme;
                          final color = showTyping ? cs.primary : cs.onSurfaceVariant;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (attachState.sending)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(value: attachState.progress),
                ),
              ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const ChatBubbleSkeletonList(itemCount: 12),
                error: (e, _) => Center(child: Text('Failed: $e')),
                data: (msgs) {
                  if (me == null) return const Center(child: Text('Not signed in'));
                  // Remove pending items that already arrived from server.
                  final serverIds = msgs.map((e) => e.id).toSet();
                  if (_pendingLocal.any((m) => serverIds.contains(m.id))) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _pendingLocal.removeWhere((m) => serverIds.contains(m.id)));
                    });
                  }

                  final pending = _pendingLocal.where((m) => !serverIds.contains(m.id)).toList();
                  final merged = [...pending, ...msgs];

                  final visible = merged
                      .where((m) => !m.deletedFor.contains(me.uid))
                      .toList(growable: false);
                  if (visible.isEmpty) {
                    return ListView(
                      reverse: true,
                      children: const [
                        SizedBox(height: 220),
                        EmptyState(
                          icon: Icons.waving_hand_outlined,
                          title: 'No messages yet',
                          message: 'Send a message to start the conversation.',
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final m = visible[i];
                      final isMe = m.senderUid == me.uid;
                      return GestureDetector(
                        onLongPress: () async {
                          if (m.type == MessageType.call) return;
                          final now = DateTime.now();
                          final canDeleteForEveryone = isMe &&
                              now.difference(m.createdAt).inMinutes <= 60 &&
                              !m.deletedForAll;
                          final action = await showModalBottomSheet<_MsgAction>(
                            context: context,
                            showDragHandle: true,
                            builder: (_) => _MessageActionsSheet(
                              isMe: isMe,
                              isStarred: m.starredBy.contains(me.uid),
                              canDeleteForEveryone: canDeleteForEveryone,
                            ),
                          );
                          if (!mounted || action == null) return;
                          switch (action) {
                            case _MsgAction.reply:
                              setState(() => _replyTo = m);
                              break;
                            case _MsgAction.forward:
                              await _forwardMessage(message: m);
                              break;
                            case _MsgAction.star:
                              await _toggleStar(m);
                              break;
                            case _MsgAction.deleteForMe:
                              await _deleteMessageForMe(m);
                              break;
                            case _MsgAction.deleteForEveryone:
                              await _deleteMessageForEveryone(m);
                              break;
                          }
                        },
                        child: _MessageBubble(
                          message: m,
                          isMe: isMe,
                          myUid: me.uid,
                          otherUid: widget.otherUid,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _controller,
              onAttach: _showAttachSheet,
              pendingPreview: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyTo != null)
                    _ReplyPreview(
                      meUid: me!.uid,
                      message: _replyTo!,
                      onRemove: () => setState(() => _replyTo = null),
                    ),
                  if (_pendingImage != null || _pendingFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _pendingImage != null
                          ? PendingImagePreview(
                              path: _pendingImage!.path,
                              onRemove: () => setState(() => _pendingImage = null),
                            )
                          : _PendingFilePreview(
                              fileName: _pendingFile!.name,
                              sizeBytes: _pendingFile!.size,
                              onRemove: () => setState(() => _pendingFile = null),
                            ),
                    ),
                ],
              ),
              onChanged: (v) {
                _setTyping(v.trim().isNotEmpty);
                _typingDebounce?.cancel();
                _typingDebounce = Timer(const Duration(seconds: 2), () => _setTyping(false));
              },
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final String meUid;
  final Message message;
  final VoidCallback onRemove;

  const _ReplyPreview({
    required this.meUid,
    required this.message,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMe = message.senderUid == meUid;
    final label = isMe ? 'You' : 'Reply';

    String snippet() {
      switch (message.type) {
        case MessageType.image:
          return (message.text.trim().isEmpty) ? '📷 Photo' : message.text.trim();
        case MessageType.file:
          return '📎 ${message.fileName ?? 'File'}';
        case MessageType.call:
          return message.text.trim().isEmpty ? 'Call' : message.text.trim();
        case MessageType.text:
          return message.text.trim();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  snippet(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

enum _MsgAction { reply, forward, star, deleteForMe, deleteForEveryone }

class _MessageActionsSheet extends StatelessWidget {
  final bool isMe;
  final bool isStarred;
  final bool canDeleteForEveryone;

  const _MessageActionsSheet({
    required this.isMe,
    required this.isStarred,
    required this.canDeleteForEveryone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: const Text('Reply'),
            onTap: () => Navigator.of(context).pop(_MsgAction.reply),
          ),
          ListTile(
            leading: const Icon(Icons.forward_rounded),
            title: const Text('Forward'),
            onTap: () => Navigator.of(context).pop(_MsgAction.forward),
          ),
          ListTile(
            leading: Icon(isStarred ? Icons.star_rounded : Icons.star_outline_rounded),
            title: Text(isStarred ? 'Unstar' : 'Star'),
            onTap: () => Navigator.of(context).pop(_MsgAction.star),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: cs.error),
            title: Text('Delete for me', style: TextStyle(color: cs.error)),
            onTap: () => Navigator.of(context).pop(_MsgAction.deleteForMe),
          ),
          if (canDeleteForEveryone)
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: cs.error),
              title: Text('Delete for everyone (1h)', style: TextStyle(color: cs.error)),
              onTap: () => Navigator.of(context).pop(_MsgAction.deleteForEveryone),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ForwardToSheet extends ConsumerStatefulWidget {
  final String myUid;
  const _ForwardToSheet({required this.myUid});

  @override
  ConsumerState<_ForwardToSheet> createState() => _ForwardToSheetState();
}

class _ForwardToSheetState extends ConsumerState<_ForwardToSheet> {
  final _q = TextEditingController();
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendshipsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Forward to',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(_selected.toList()),
                        child: Text('Send (${_selected.length})'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _q,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search friends',
                    ),
                  ),
                ),
                Expanded(
                  child: friendsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Failed: $e')),
                    data: (friends) {
                      final ids = friends
                          .map((f) => f.uidA == widget.myUid ? f.uidB : f.uidA)
                          .where((id) => id.isNotEmpty)
                          .toList();

                      final term = _q.text.trim().toLowerCase();
                      final filtered = term.isEmpty
                          ? ids
                          : ids.where((id) => id.toLowerCase().contains(term)).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No friends found'));
                      }

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final uid = filtered[i];
                          final u = ref.watch(userProfileProvider(uid)).valueOrNull;
                          final selected = _selected.contains(uid);
                          return ListTile(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(uid);
                                } else {
                                  _selected.add(uid);
                                }
                              });
                            },
                            leading: CustomAvatar(
                              height: 42,
                              width: 42,
                              name: u?.displayName ?? uid,
                              image: u?.photoUrl ?? '',
                              base64: u?.photoBase64,
                              network: (u?.photoUrl ?? '').isNotEmpty,
                            ),
                            title: Text(u?.displayName ?? uid),
                            trailing: Checkbox(
                              value: selected,
                              onChanged: (_) {
                                setState(() {
                                  if (selected) {
                                    _selected.remove(uid);
                                  } else {
                                    _selected.add(uid);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAttach;
  final Widget? pendingPreview;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.onAttach,
    required this.pendingPreview,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pendingPreview ?? const SizedBox.shrink(),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Attach',
                        onPressed: onAttach,
                        icon: const Icon(Icons.add_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          onChanged: onChanged,
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onSend,
                        child: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingFilePreview extends StatelessWidget {
  final String fileName;
  final int sizeBytes;
  final VoidCallback onRemove;

  const _PendingFilePreview({
    required this.fileName,
    required this.sizeBytes,
    required this.onRemove,
  });

  String _prettyBytes(int b) {
    if (b < 1024) return '${b}B';
    final kb = b / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)}KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _prettyBytes(sizeBytes),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  final String myUid;
  final String otherUid;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.myUid,
    required this.otherUid,
  });

  bool get _isDelivered => otherUid.isNotEmpty && message.deliveredTo.contains(otherUid);
  bool get _isRead => otherUid.isNotEmpty && message.readBy.contains(otherUid);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // WhatsApp-like dark colors (close to the screenshot).
    const waOutDark = Color(0xFF005C4B); // outgoing bubble
    const waInDark = Color(0xFF202C33); // incoming bubble

    final bg = isMe
        ? (isDark ? waOutDark : cs.primaryContainer)
        : (isDark ? waInDark : cs.surface);
    final fg = isDark ? Colors.white : (isMe ? cs.onPrimaryContainer : cs.onSurface);
    final time = DateFormat('h:mm a').format(message.createdAt).toLowerCase();

    if (message.type == MessageType.call) {
      final label = message.text.trim().isEmpty
          ? ((message.callType ?? 'audio') == 'video' ? 'Video call' : 'Voice call')
          : message.text.trim();
      final icon =
          (message.callType ?? 'audio') == 'video' ? Icons.videocam_rounded : Icons.call_rounded;
      final subtle = cs.onSurfaceVariant;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: subtle),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: subtle,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: subtle,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final deletedEverywhere =
        message.deletedForAll || message.text.trim().toLowerCase() == 'message deleted';
    if (deletedEverywhere) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2A30) : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'This message was deleted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.78)
                            : cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget? receipt() {
      if (!isMe) return null;
      // If this message isn't mine (or uid missing), never show receipt.
      if (message.senderUid != myUid) return null;

      final icon = _isDelivered || _isRead ? Icons.done_all : Icons.done;
      final Color color;
      if (_isRead) {
        // WhatsApp-like "seen" blue.
        color = const Color(0xFF53BDEB);
      } else {
        // Grey-ish for sent/delivered.
        color = isDark ? const Color(0xFFB9C4CC) : cs.onSurfaceVariant;
      }

      return Icon(icon, size: 16, color: color);
    }

    Widget? forwardedLabel() {
      if (!message.isForwarded) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forward_rounded,
              size: 14,
              color: isDark ? Colors.white.withValues(alpha: 0.75) : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Forwarded',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.75) : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
    }

    Widget content() {
      switch (message.type) {
        case MessageType.text:
          return Text(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: fg,
                  height: 1.25,
                ),
          );
        case MessageType.image:
          final url = message.mediaUrl ?? '';
          final b64 = message.mediaBase64 ?? '';
          if (url.isEmpty && b64.isEmpty) {
            return Text('Image', style: TextStyle(color: fg));
          }
          if (url.isEmpty && b64.isNotEmpty) {
            final bytes = base64Decode(b64);
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => Dialog(
                      insetPadding: const EdgeInsets.all(12),
                      child: InteractiveViewer(
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  height: 180,
                  width: 240,
                ),
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => Dialog(
                    insetPadding: const EdgeInsets.all(12),
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                height: 180,
                width: 240,
                placeholder: (context, url) => Container(
                  height: 180,
                  width: 240,
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  width: 240,
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          );
        case MessageType.file:
          final name = message.fileName ?? 'File';
          final url = message.mediaUrl ?? '';
          final b64 = message.mediaBase64 ?? '';
          return InkWell(
            onTap: () async {
              if (url.isNotEmpty) {
                await FileDownloadAndOpen.downloadAndOpen(url: url, fileName: name);
                return;
              }
              if (b64.isNotEmpty) {
                final bytes = base64Decode(b64);
                await FileDownloadAndOpen.saveBytesAndOpen(bytes: bytes, fileName: name);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file_outlined, color: fg),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        case MessageType.call:
          // Handled above as a centered system-like chip.
          return const SizedBox.shrink();
      }
    }

    Widget? replySnippet() {
      final toId = message.replyToMessageId;
      if (toId == null || toId.isEmpty) return null;

      final cs = Theme.of(context).colorScheme;
      final who = (message.replyToSenderUid ?? '') == myUid ? 'You' : 'Reply';
      final txt = (message.replyToText ?? '').trim();
      final type = (message.replyToType ?? '').toLowerCase();
      final prefix = switch (type) {
        'image' => '📷 ',
        'file' => '📎 ',
        'call' => '📞 ',
        _ => '',
      };

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF53BDEB) : cs.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : cs.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$prefix${txt.isEmpty ? 'Message' : txt}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.74,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: isMe ? null : Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (forwardedLabel() != null) forwardedLabel()!,
                  if (replySnippet() != null) replySnippet()!,
                  content(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (receipt() != null) ...[
                        const SizedBox(width: 4),
                        receipt()!,
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Positioned(
            //   bottom: 8,
            //   right: isMe ? 4 : null,
            //   left: isMe ? null : 4,
            //   child: CustomPaint(
            //     size: const Size(12, 10),
            //     painter: _BubbleTailPainter(
            //       color: bg,
            //       stroke: isMe ? null : cs.outlineVariant,
            //       isMe: isMe,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color? stroke;
  final bool isMe;

  _BubbleTailPainter({
    required this.color,
    required this.stroke,
    required this.isMe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    if (isMe) {
      // Right tail
      p.moveTo(0, 0);
      p.lineTo(size.width, size.height / 2);
      p.lineTo(0, size.height);
      p.close();
    } else {
      // Left tail
      p.moveTo(size.width, 0);
      p.lineTo(0, size.height / 2);
      p.lineTo(size.width, size.height);
      p.close();
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(p, fillPaint);

    if (stroke != null) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = stroke!;
      canvas.drawPath(p, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.stroke != stroke ||
        oldDelegate.isMe != isMe;
  }
}

