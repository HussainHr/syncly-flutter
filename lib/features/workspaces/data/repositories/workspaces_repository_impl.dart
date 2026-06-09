import '../../domain/entities/channel.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_member.dart';
import '../../domain/repositories/workspaces_repository.dart';
import '../datasources/workspaces_remote_data_source.dart';

class WorkspacesRepositoryImpl implements WorkspacesRepository {
  final WorkspacesRemoteDataSource _remote;

  WorkspacesRepositoryImpl(this._remote);

  @override
  Stream<List<Workspace>> watchMyWorkspaces(String myUid) =>
      _remote.watchMyWorkspaces(myUid);

  @override
  Stream<List<Channel>> watchChannels(String workspaceId) =>
      _remote.watchChannels(workspaceId);

  @override
  Stream<Workspace?> watchWorkspace(String workspaceId) =>
      _remote.watchWorkspace(workspaceId);

  @override
  Future<WorkspaceMember?> getMyMembership({
    required String workspaceId,
    required String myUid,
  }) =>
      _remote.getMyMembership(workspaceId: workspaceId, myUid: myUid);

  @override
  Future<Workspace> createWorkspace({
    required String name,
    required String createdBy,
    required String creatorDisplayName,
  }) =>
      _remote.createWorkspace(
        name: name,
        createdBy: createdBy,
        creatorDisplayName: creatorDisplayName,
      );

  @override
  Future<Workspace> joinWorkspace({
    required String inviteCode,
    required String myUid,
    required String myDisplayName,
  }) =>
      _remote.joinWorkspace(
        inviteCode: inviteCode,
        myUid: myUid,
        myDisplayName: myDisplayName,
      );

  @override
  Future<Channel> createChannel({
    required String workspaceId,
    required String name,
    required String createdBy,
  }) =>
      _remote.createChannel(
        workspaceId: workspaceId,
        name: name,
        createdBy: createdBy,
      );
}
