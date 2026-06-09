import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/features/workspaces/domain/entities/workspace_member.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspace_actions_controller.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspaces_streams.dart';

class WorkspaceChannelsPage extends ConsumerWidget {
  final String workspaceId;

  const WorkspaceChannelsPage({super.key, required this.workspaceId});

  Future<void> _showCreateChannelSheet(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create text channel',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Channel name',
                    hintText: 'announcements',
                    prefixText: '# ',
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Channel name is required';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(ctx).pop(controller.text.trim());
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(ctx).pop(controller.text.trim());
                    }
                  },
                  child: const Text('Create channel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (name == null || name.isEmpty) return;

    final channel = await ref.read(workspaceActionsControllerProvider.notifier).createChannel(
          workspaceId: workspaceId,
          name: name,
        );
    if (channel != null && context.mounted) {
      showToast('Channel ${channel.displayName} created');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(workspaceProvider(workspaceId));
    final channelsAsync = ref.watch(workspaceChannelsProvider(workspaceId));
    final membershipAsync = ref.watch(myWorkspaceMembershipProvider(workspaceId));
    final actionsState = ref.watch(workspaceActionsControllerProvider);

    ref.listen(workspaceActionsControllerProvider, (prev, next) {
      final msg = next.error;
      if (msg != null && msg.isNotEmpty) {
        showToast(msg);
        ref.read(workspaceActionsControllerProvider.notifier).clearError();
      }
    });

    final isOwner = membershipAsync.valueOrNull?.role == WorkspaceMemberRole.owner;

    return Scaffold(
      appBar: AppBar(
        title: workspaceAsync.when(
          loading: () => const Text('Channels'),
          error: (_, __) => const Text('Channels'),
          data: (workspace) => Text(workspace?.name ?? 'Channels'),
        ),
        actions: [
          workspaceAsync.maybeWhen(
            data: (workspace) {
              if (workspace == null || !isOwner) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Copy invite code',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: workspace.inviteCode));
                  showToast('Invite code copied');
                },
                icon: const Icon(Icons.vpn_key_outlined),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load channels: $e')),
        data: (channels) {
          if (channels.isEmpty) {
            return const EmptyState(
              icon: Icons.tag_outlined,
              title: 'No channels yet',
              message: 'Create a text channel to get started.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: channels.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final channel = channels[index];
              final preview = channel.lastMessage?.text.trim();
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: Icon(
                  Icons.tag_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  channel.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: preview == null || preview.isEmpty
                    ? const Text('Text channel')
                    : Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(
                  '/workspaces/$workspaceId/channels/${channel.id}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: actionsState.isLoading
                  ? null
                  : () => _showCreateChannelSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New channel'),
            )
          : null,
      bottomNavigationBar: workspaceAsync.maybeWhen(
        data: (workspace) {
          if (workspace == null || !isOwner) return null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Invite code',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            workspace.inviteCode,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: workspace.inviteCode),
                        );
                        showToast('Invite code copied');
                      },
                      child: const Text('Copy'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
