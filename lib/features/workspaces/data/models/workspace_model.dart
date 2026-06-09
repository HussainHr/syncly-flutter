import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/workspace.dart';

class WorkspaceModel extends Workspace {
  const WorkspaceModel({
    required super.id,
    required super.name,
    required super.inviteCode,
    required super.createdBy,
    required super.memberCount,
    required super.createdAt,
    required super.updatedAt,
  });

  static DateTime _readDate(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    return fallback ?? DateTime.now();
  }

  factory WorkspaceModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = _readDate(data['createdAt']);
    return WorkspaceModel(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Workspace',
      inviteCode: (data['inviteCode'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      memberCount: (data['memberCount'] as int?) ?? 0,
      createdAt: createdAt,
      updatedAt: _readDate(data['updatedAt'], fallback: createdAt),
    );
  }
}
