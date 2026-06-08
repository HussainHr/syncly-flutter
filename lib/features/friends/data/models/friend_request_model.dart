import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/friend_request.dart';

class FriendRequestModel extends FriendRequest {
  const FriendRequestModel({
    required super.id,
    required super.fromUid,
    required super.toUid,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  static FriendRequestStatus _statusFromString(String? v) {
    return switch ((v ?? '').toLowerCase()) {
      'accepted' => FriendRequestStatus.accepted,
      'rejected' => FriendRequestStatus.rejected,
      'cancelled' => FriendRequestStatus.cancelled,
      _ => FriendRequestStatus.pending,
    };
  }

  static String statusToString(FriendRequestStatus s) {
    return switch (s) {
      FriendRequestStatus.pending => 'pending',
      FriendRequestStatus.accepted => 'accepted',
      FriendRequestStatus.rejected => 'rejected',
      FriendRequestStatus.cancelled => 'cancelled',
    };
  }

  static DateTime _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  factory FriendRequestModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FriendRequestModel(
      id: doc.id,
      fromUid: (data['fromUid'] as String?) ?? '',
      toUid: (data['toUid'] as String?) ?? '',
      status: _statusFromString(data['status'] as String?),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }
}

