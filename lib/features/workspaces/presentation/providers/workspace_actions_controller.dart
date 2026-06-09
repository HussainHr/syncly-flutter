import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

import '../../domain/entities/channel.dart';
import '../../domain/entities/workspace.dart';
import 'workspaces_providers.dart';

class WorkspaceActionsState {
  final bool isLoading;
  final String? error;

  const WorkspaceActionsState({required this.isLoading, this.error});

  factory WorkspaceActionsState.initial() =>
      const WorkspaceActionsState(isLoading: false);

  WorkspaceActionsState copyWith({bool? isLoading, String? error}) {
    return WorkspaceActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final workspaceActionsControllerProvider =
    StateNotifierProvider<WorkspaceActionsController, WorkspaceActionsState>((ref) {
  return WorkspaceActionsController(ref);
});

class WorkspaceActionsController extends StateNotifier<WorkspaceActionsState> {
  final Ref _ref;

  WorkspaceActionsController(this._ref) : super(WorkspaceActionsState.initial());

  void clearError() => state = state.copyWith(error: null);

  Future<Workspace?> createWorkspace({required String name}) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) {
      state = state.copyWith(error: 'Not signed in.');
      return null;
    }

    final profile = await _ref.read(userProfileProvider(me.uid).future);
    final displayName = profile?.displayName ?? me.email ?? 'User';

    state = state.copyWith(isLoading: true, error: null);
    try {
      final workspace = await _ref.read(workspacesRepositoryProvider).createWorkspace(
            name: name,
            createdBy: me.uid,
            creatorDisplayName: displayName,
          );
      state = state.copyWith(isLoading: false, error: null);
      return workspace;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Workspace?> joinWorkspace({required String inviteCode}) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) {
      state = state.copyWith(error: 'Not signed in.');
      return null;
    }

    final profile = await _ref.read(userProfileProvider(me.uid).future);
    final displayName = profile?.displayName ?? me.email ?? 'User';

    state = state.copyWith(isLoading: true, error: null);
    try {
      final workspace = await _ref.read(workspacesRepositoryProvider).joinWorkspace(
            inviteCode: inviteCode,
            myUid: me.uid,
            myDisplayName: displayName,
          );
      state = state.copyWith(isLoading: false, error: null);
      return workspace;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Channel?> createChannel({
    required String workspaceId,
    required String name,
  }) async {
    final me = _ref.read(currentUserProvider);
    if (me == null) {
      state = state.copyWith(error: 'Not signed in.');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final channel = await _ref.read(workspacesRepositoryProvider).createChannel(
            workspaceId: workspaceId,
            name: name,
            createdBy: me.uid,
          );
      state = state.copyWith(isLoading: false, error: null);
      return channel;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
