import 'package:equatable/equatable.dart';

class ChatUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final bool isOnline;

  const ChatUser({
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.displayName,
    this.photoUrl,
    this.lastSeenAt,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    createdAt,
    updatedAt,
    lastSeenAt,
    isOnline,
  ];
}

