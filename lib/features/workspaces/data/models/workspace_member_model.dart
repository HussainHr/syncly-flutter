import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/workspace_member.dart';

class WorkspaceMemberModel extends WorkspaceMember {
  const WorkspaceMemberModel({
    required super.workspaceId,
    required super.uid,
    required super.displayName,
    required super.role,
    required super.joinedAt,
  });

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static WorkspaceMemberRole _roleFromString(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'owner' => WorkspaceMemberRole.owner,
      _ => WorkspaceMemberRole.member,
    };
  }

  factory WorkspaceMemberModel.fromDoc({
    required String workspaceId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return WorkspaceMemberModel(
      workspaceId: workspaceId,
      uid: (data['uid'] as String?) ?? doc.id,
      displayName: (data['displayName'] as String?) ?? '',
      role: _roleFromString(data['role'] as String?),
      joinedAt: _readDate(data['joinedAt']),
    );
  }
}
