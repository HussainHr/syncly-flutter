import 'package:equatable/equatable.dart';

enum WorkspaceMemberRole { owner, member }

class WorkspaceMember extends Equatable {
  final String workspaceId;
  final String uid;
  final String displayName;
  final WorkspaceMemberRole role;
  final DateTime joinedAt;

  const WorkspaceMember({
    required this.workspaceId,
    required this.uid,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  bool get isOwner => role == WorkspaceMemberRole.owner;

  @override
  List<Object?> get props => [workspaceId, uid, displayName, role, joinedAt];
}
