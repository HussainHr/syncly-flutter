import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspaces_streams.dart';

class ChannelDetailPage extends ConsumerWidget {
  final String workspaceId;
  final String channelId;

  const ChannelDetailPage({
    super.key,
    required this.workspaceId,
    required this.channelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(workspaceChannelsProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(
        title: channelsAsync.when(
          loading: () => const Text('Channel'),
          error: (_, __) => const Text('Channel'),
          data: (channels) {
            String title = 'Channel';
            for (final channel in channels) {
              if (channel.id == channelId) {
                title = channel.displayName;
                break;
              }
            }
            return Text(title);
          },
        ),
      ),
      body: const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Channel chat opens in Sprint 3',
        message: 'Realtime messaging, typing, and read receipts will be added here.',
      ),
    );
  }
}
