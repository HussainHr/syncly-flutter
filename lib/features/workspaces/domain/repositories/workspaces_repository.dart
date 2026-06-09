import '../entities/channel.dart';
import '../entities/workspace.dart';
import '../entities/workspace_member.dart';

abstract class WorkspacesRepository {
  Stream<List<Workspace>> watchMyWorkspaces(String myUid);

  Stream<List<Channel>> watchChannels(String workspaceId);

  Stream<Workspace?> watchWorkspace(String workspaceId);

  Future<WorkspaceMember?> getMyMembership({
    required String workspaceId,
    required String myUid,
  });

  Future<Workspace> createWorkspace({
    required String name,
    required String createdBy,
    required String creatorDisplayName,
  });

  Future<Workspace> joinWorkspace({
    required String inviteCode,
    required String myUid,
    required String myDisplayName,
  });

  Future<Channel> createChannel({
    required String workspaceId,
    required String name,
    required String createdBy,
  });
}
