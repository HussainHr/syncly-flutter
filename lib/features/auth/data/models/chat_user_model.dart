import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_user.dart';

class ChatUserModel extends ChatUser {
  const ChatUserModel({
    required super.uid,
    required super.createdAt,
    required super.updatedAt,
    super.email,
    super.displayName,
    super.photoUrl,
    super.lastSeenAt,
    required super.isOnline,
  });

  factory ChatUserModel.fromFirestore(Map<String, dynamic> json) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatUserModel(
      uid: (json['uid'] as String?) ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: readDate(json['createdAt']),
      updatedAt: readDate(json['updatedAt']),
      lastSeenAt: json['lastSeenAt'] == null ? null : readDate(json['lastSeenAt']),
      isOnline: (json['isOnline'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastSeenAt': lastSeenAt == null ? null : Timestamp.fromDate(lastSeenAt!),
      'isOnline': isOnline,
    };
  }
}

