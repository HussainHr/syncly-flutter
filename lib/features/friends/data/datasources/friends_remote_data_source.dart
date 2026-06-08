import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_request_model.dart';
import '../models/friendship_model.dart';

class FriendsRemoteDataSource {
  final FirebaseFirestore _db;

  FriendsRemoteDataSource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _db.collection('friendships');

  DocumentReference<Map<String, dynamic>> _blockDoc({
    required String blockerUid,
    required String blockedUid,
  }) =>
      _db.collection('users').doc(blockerUid).collection('blocked').doc(blockedUid);

  static String requestId(String fromUid, String toUid) => '${fromUid}_$toUid';

  static String friendshipId(String uid1, String uid2) {
    final a = uid1.compareTo(uid2) <= 0 ? uid1 : uid2;
    final b = uid1.compareTo(uid2) <= 0 ? uid2 : uid1;
    return '${a}_$b';
  }

  Stream<List<FriendRequestModel>> watchIncoming(String myUid) {
    return _requests
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) {
          final list =
              s.docs.map(FriendRequestModel.fromDoc).toList(growable: false);
          final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sorted;
        });
  }

  Stream<List<FriendRequestModel>> watchOutgoing(String myUid) {
    return _requests
        .where('fromUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) {
          final list =
              s.docs.map(FriendRequestModel.fromDoc).toList(growable: false);
          final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sorted;
        });
  }

  Stream<List<FriendshipModel>> watchFriendships(String myUid) {
    return _friendships
        .where('users', arrayContains: myUid)
        .snapshots()
        .map((s) {
          final list =
              s.docs.map(FriendshipModel.fromDoc).toList(growable: false);
          final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sorted;
        });
  }

  Future<void> sendRequest({required String fromUid, required String toUid}) async {
    final id = requestId(fromUid, toUid);
    final ref = _requests.doc(id);
    await ref.set({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // In-app notification (works without Cloud Functions/Blaze).
    await _db.collection('notifications').add({
      'type': 'friend_request',
      'toUid': toUid,
      'fromUid': fromUid,
      'requestId': id,
      'title': 'Friend request',
      'body': 'You have a new friend request',
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  Future<void> cancelRequest({required String fromUid, required String toUid}) async {
    final id = requestId(fromUid, toUid);
    await _requests.doc(id).set({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> rejectRequest({required String requestId}) async {
    await _requests.doc(requestId).set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptRequest({
    required String requestId,
    required String myUid,
  }) async {
    final reqRef = _requests.doc(requestId);

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) return;
      final data = reqSnap.data() as Map<String, dynamic>;
      if ((data['status'] as String?) != 'pending') return;

      final fromUid = data['fromUid'] as String?;
      final toUid = data['toUid'] as String?;
      if (fromUid == null || toUid == null) return;
      if (toUid != myUid) return;

      final fid = friendshipId(fromUid, toUid);
      final frRef = _friendships.doc(fid);

      tx.set(frRef, {
        'users': [fromUid, toUid],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(reqRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> unfriend({required String myUid, required String otherUid}) async {
    final fid = friendshipId(myUid, otherUid);
    await _friendships.doc(fid).delete();
  }

  Stream<bool> watchIsBlocked({
    required String blockerUid,
    required String blockedUid,
  }) {
    return _blockDoc(blockerUid: blockerUid, blockedUid: blockedUid)
        .snapshots()
        .map((d) => d.exists);
  }

  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final ref = _blockDoc(blockerUid: blockerUid, blockedUid: blockedUid);
    await ref.set({
      'blockedUid': blockedUid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Optional: also remove friendship if exists
    final fid = friendshipId(blockerUid, blockedUid);
    await _friendships.doc(fid).delete().catchError((_) {});
  }

  Future<void> unblockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    await _blockDoc(blockerUid: blockerUid, blockedUid: blockedUid).delete();
  }
}

