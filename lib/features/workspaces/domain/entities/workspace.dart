import 'package:equatable/equatable.dart';

class Workspace extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workspace({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        inviteCode,
        createdBy,
        memberCount,
        createdAt,
        updatedAt,
      ];
}
