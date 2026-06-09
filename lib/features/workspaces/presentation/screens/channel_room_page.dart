import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/core/widgets/skeletons/chat_bubble_skeleton.dart';
import 'package:syncly/features/chats/domain/entities/message.dart';
import 'package:syncly/features/chats/presentation/widgets/pending_image_preview.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';
import 'package:syncly/features/workspaces/presentation/providers/channel_attachment_send_controller.dart';
import 'package:syncly/features/workspaces/presentation/providers/channel_chat_providers.dart';
import 'package:syncly/features/workspaces/presentation/providers/channel_chat_streams.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspaces_streams.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ChannelRoomPage extends ConsumerStatefulWidget {
  final String workspaceId;
  final String channelId;

  const ChannelRoomPage({
    super.key,
    required this.workspaceId,
    required this.channelId,
  });

  @override
  ConsumerState<ChannelRoomPage> createState() => _ChannelRoomPageState();
}

class _ChannelRoomPageState extends ConsumerState<ChannelRoomPage> {
  final _controller = TextEditingController();
  Timer? _typingDebounce;
  XFile? _pendingImage;
  final List<Message> _pendingLocal = <Message>[];

  ChannelRef get _channelRef => (
        workspaceId: widget.workspaceId,
        channelId: widget.channelId,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _setTyping(false);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final profile = ref.read(userProfileProvider(me.uid)).valueOrNull;
    await ref.read(channelChatRepositoryProvider).markChannelRead(
          workspaceId: widget.workspaceId,
          channelId: widget.channelId,
          myUid: me.uid,
          sendReadReceipts: profile?.readReceiptsEnabled ?? true,
        );
  }

  void _setTyping(bool value) {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final profile = ref.read(userProfileProvider(me.uid)).valueOrNull;
    if (profile?.typingIndicatorEnabled == false) return;
    ref.read(channelChatRepositoryProvider).setTyping(
          workspaceId: widget.workspaceId,
          channelId: widget.channelId,
          myUid: me.uid,
          isTyping: value,
        );
  }

  Future<void> _send() async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final text = _controller.text;
    _controller.clear();
    _setTyping(false);

    if (_pendingImage != null) {
      final path = _pendingImage!.path;
      final caption = text.trim();
      setState(() => _pendingImage = null);
      await ref.read(channelAttachmentSendControllerProvider.notifier).sendImage(
            workspaceId: widget.workspaceId,
            channelId: widget.channelId,
            filePath: path,
            caption: caption.isEmpty ? null : caption,
          );
      await _markRead();
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final localId = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .collection('channels')
        .doc(widget.channelId)
        .collection('messages')
        .doc()
        .id;

    final localMsg = Message(
      id: localId,
      chatId: widget.channelId,
      senderUid: me.uid,
      type: MessageType.text,
      text: trimmed,
      createdAt: DateTime.now(),
      deliveredTo: [me.uid],
      readBy: [me.uid],
    );

    setState(() => _pendingLocal.insert(0, localMsg));

    try {
      await ref.read(channelChatRepositoryProvider).sendTextMessage(
            workspaceId: widget.workspaceId,
            channelId: widget.channelId,
            myUid: me.uid,
            text: trimmed,
            messageId: localId,
          );
      await _markRead();
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingLocal.removeWhere((m) => m.id == localId));
      showToast('Send failed: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
    );
    if (file == null) return;
    setState(() => _pendingImage = file);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final channelsAsync = ref.watch(workspaceChannelsProvider(widget.workspaceId));
    final messagesAsync = ref.watch(channelMessagesProvider(_channelRef));
    final typingAsync = ref.watch(channelTypingMembersProvider(_channelRef));
    final attachState = ref.watch(channelAttachmentSendControllerProvider);

    final channelTitle = channelsAsync.maybeWhen(
      data: (channels) {
        for (final c in channels) {
          if (c.id == widget.channelId) return c.displayName;
        }
        return 'Channel';
      },
      orElse: () => 'Channel',
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/workspaces/${widget.workspaceId}');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              channelTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            typingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (uids) {
                if (uids.isEmpty) return const SizedBox.shrink();
                final label = uids.length == 1 ? 'Someone is typing…' : '${uids.length} people typing…';
                return Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                );
              },
            ),
          ],
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

                  final serverIds = msgs.map((e) => e.id).toSet();
                  if (_pendingLocal.any((m) => serverIds.contains(m.id))) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _pendingLocal.removeWhere((m) => serverIds.contains(m.id)));
                    });
                  }

                  final pending =
                      _pendingLocal.where((m) => !serverIds.contains(m.id)).toList();
                  final merged = [...pending, ...msgs];

                  if (merged.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nSay hello to the channel!',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: merged.length,
                    itemBuilder: (context, i) {
                      final m = merged[i];
                      final isMe = m.senderUid == me.uid;
                      return _ChannelMessageBubble(
                        message: m,
                        isMe: isMe,
                        myUid: me.uid,
                      );
                    },
                  );
                },
              ),
            ),
            _ChannelComposer(
              controller: _controller,
              pendingPreview: _pendingImage == null
                  ? null
                  : PendingImagePreview(
                      path: _pendingImage!.path,
                      onRemove: () => setState(() => _pendingImage = null),
                    ),
              onAttachImage: _pickImage,
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

class _ChannelComposer extends StatelessWidget {
  final TextEditingController controller;
  final Widget? pendingPreview;
  final VoidCallback onAttachImage;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _ChannelComposer({
    required this.controller,
    required this.pendingPreview,
    required this.onAttachImage,
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
          if (pendingPreview != null) ...[
            pendingPreview!,
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              IconButton(
                tooltip: 'Photo',
                onPressed: onAttachImage,
                icon: const Icon(Icons.image_outlined),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      hintText: 'Message #channel',
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSend,
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelMessageBubble extends ConsumerWidget {
  final Message message;
  final bool isMe;
  final String myUid;

  const _ChannelMessageBubble({
    required this.message,
    required this.isMe,
    required this.myUid,
  });

  bool _readByOthers(List<String> readBy) =>
      readBy.any((uid) => uid.isNotEmpty && uid != myUid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isMe
        ? (isDark ? const Color(0xFF005C4B) : cs.primaryContainer)
        : (isDark ? const Color(0xFF202C33) : cs.surface);
    final fg = isDark ? Colors.white : (isMe ? cs.onPrimaryContainer : cs.onSurface);
    final time = DateFormat('h:mm a').format(message.createdAt).toLowerCase();
    final sender = ref.watch(userProfileProvider(message.senderUid)).valueOrNull;

    Widget content() {
      switch (message.type) {
        case MessageType.text:
          return Text(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: fg, height: 1.25),
          );
        case MessageType.image:
          final b64 = message.mediaBase64 ?? '';
          final url = message.mediaUrl ?? '';
          if (b64.isNotEmpty) {
            final bytes = base64Decode(b64);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(bytes, fit: BoxFit.cover, height: 180, width: 240),
                ),
                if (message.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(message.text, style: TextStyle(color: fg)),
                ],
              ],
            );
          }
          if (url.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                height: 180,
                width: 240,
              ),
            );
          }
          return Text('Image', style: TextStyle(color: fg));
        case MessageType.file:
        case MessageType.call:
          return Text(message.text, style: TextStyle(color: fg));
      }
    }

    Widget? receipt() {
      if (!isMe) return null;
      final read = _readByOthers(message.readBy);
      final icon = read ? Icons.done_all : Icons.done;
      final color = read ? const Color(0xFF53BDEB) : cs.onSurfaceVariant;
      return Icon(icon, size: 16, color: color);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
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
            border: isMe ? null : Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  sender?.displayName ?? message.senderUid,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                ),
              if (!isMe) const SizedBox(height: 4),
              content(),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
