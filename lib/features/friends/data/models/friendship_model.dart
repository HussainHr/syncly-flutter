import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friendship.dart';

class FriendshipModel extends Friendship {
  const FriendshipModel({
    required super.id,
    required super.uidA,
    required super.uidB,
    required super.createdAt,
  });

  static DateTime _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  factory FriendshipModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final users = (data['users'] as List?)?.cast<String>() ?? const <String>[];
    final uidA = users.isNotEmpty ? users.first : '';
    final uidB = users.length > 1 ? users[1] : '';
    return FriendshipModel(
      id: doc.id,
      uidA: uidA,
      uidB: uidB,
      createdAt: _readDate(data['createdAt']),
    );
  }
}

