import 'package:equatable/equatable.dart';

enum FriendRequestStatus { pending, accepted, rejected, cancelled }

class FriendRequest extends Equatable {
  final String id;
  final String fromUid;
  final String toUid;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, fromUid, toUid, status, createdAt, updatedAt];
}

