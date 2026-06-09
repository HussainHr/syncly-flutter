import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/features/auth/domain/entities/user_role.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspaces_streams.dart';

class WorkspacesPage extends ConsumerWidget {
  const WorkspacesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final workspacesAsync = ref.watch(myWorkspacesProvider);
    final profileAsync = me == null ? null : ref.watch(userProfileProvider(me.uid));

    final appRole = profileAsync?.valueOrNull?.role ?? UserRole.member;
    final isHost = appRole == UserRole.host;

    return Scaffold(
      body: workspacesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load workspaces: $e')),
        data: (workspaces) {
          if (workspaces.isEmpty) {
            return EmptyState(
              icon: Icons.hub_outlined,
              title: 'No workspaces yet',
              message: isHost
                  ? 'Create a workspace or join one with an invite code.'
                  : 'Join a workspace using an invite code from your host.',
              action: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (isHost)
                    FilledButton.icon(
                      onPressed: () => context.push('/workspaces/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create workspace'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/workspaces/join'),
                    icon: const Icon(Icons.login),
                    label: const Text('Join workspace'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: workspaces.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final workspace = workspaces[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.workspaces_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    workspace.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${workspace.memberCount} member${workspace.memberCount == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/workspaces/${workspace.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: workspacesAsync.maybeWhen(
        data: (workspaces) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'join_workspace',
                onPressed: () => context.push('/workspaces/join'),
                icon: const Icon(Icons.login),
                label: const Text('Join'),
              ),
              if (isHost) ...[
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'create_workspace',
                  onPressed: () => context.push('/workspaces/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ],
          );
        },
        orElse: () => null,
      ),
    );
  }
}
