import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';

import '../../domain/entities/channel.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_member.dart';
import 'workspaces_providers.dart';

final myWorkspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream<List<Workspace>>.empty();
  return ref.watch(workspacesRepositoryProvider).watchMyWorkspaces(me.uid);
});

final workspaceProvider =
    StreamProvider.family<Workspace?, String>((ref, workspaceId) {
  return ref.watch(workspacesRepositoryProvider).watchWorkspace(workspaceId);
});

final workspaceChannelsProvider =
    StreamProvider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspacesRepositoryProvider).watchChannels(workspaceId);
});

final myWorkspaceMembershipProvider =
    FutureProvider.family<WorkspaceMember?, String>((ref, workspaceId) async {
  final me = ref.watch(currentUserProvider);
  if (me == null) return null;
  return ref.watch(workspacesRepositoryProvider).getMyMembership(
        workspaceId: workspaceId,
        myUid: me.uid,
      );
});
