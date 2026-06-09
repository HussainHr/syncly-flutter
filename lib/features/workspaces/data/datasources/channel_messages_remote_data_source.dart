import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../chats/data/models/message_model.dart';

class ChannelMessagesRemoteDataSource {
  final FirebaseFirestore _db;

  ChannelMessagesRemoteDataSource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _workspaceDoc(String workspaceId) =>
      _db.collection('workspaces').doc(workspaceId);

  DocumentReference<Map<String, dynamic>> _channelDoc(
    String workspaceId,
    String channelId,
  ) =>
      _workspaceDoc(workspaceId).collection('channels').doc(channelId);

  CollectionReference<Map<String, dynamic>> _messagesCol(
    String workspaceId,
    String channelId,
  ) =>
      _channelDoc(workspaceId, channelId).collection('messages');

  DocumentReference<Map<String, dynamic>> _typingDoc(
    String workspaceId,
    String channelId,
    String uid,
  ) =>
      _channelDoc(workspaceId, channelId).collection('typing').doc(uid);

  Stream<List<MessageModel>> watchMessages({
    required String workspaceId,
    required String channelId,
    int limit = 50,
  }) {
    return _messagesCol(workspaceId, channelId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MessageModel.fromDoc(channelId, d))
              .toList(growable: false),
        );
  }

  Future<void> sendTextMessage({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required String text,
    String? messageId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final channelRef = _channelDoc(workspaceId, channelId);
    final msgRef = messageId == null || messageId.isEmpty
        ? _messagesCol(workspaceId, channelId).doc()
        : _messagesCol(workspaceId, channelId).doc(messageId);

    await _db.runTransaction((tx) async {
      final wsSnap = await tx.get(_workspaceDoc(workspaceId));
      final memberUids =
          (wsSnap.data()?['memberUids'] as List?)?.cast<String>() ?? <String>[];

      tx.set(msgRef, {
        'senderUid': myUid,
        'type': 'text',
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [myUid],
        'readBy': [myUid],
      });

      final unreadUpdates = <String, dynamic>{myUid: 0};
      for (final uid in memberUids) {
        if (uid != myUid) {
          unreadUpdates[uid] = FieldValue.increment(1);
        }
      }

      tx.set(channelRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          'id': msgRef.id,
          'senderUid': myUid,
          'text': trimmed,
          'type': 'text',
          'createdAt': FieldValue.serverTimestamp(),
        },
        'unread': unreadUpdates,
      }, SetOptions(merge: true));

      for (final uid in memberUids) {
        if (uid == myUid) continue;
        final notifRef = _db.collection('notifications').doc();
        tx.set(notifRef, {
          'type': 'channel_message',
          'toUid': uid,
          'fromUid': myUid,
          'workspaceId': workspaceId,
          'channelId': channelId,
          'messageId': msgRef.id,
          'title': 'New channel message',
          'body': trimmed,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
    });
  }

  Future<void> sendImageMessage({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required String imageBase64,
    String? caption,
    required int sizeBytes,
  }) async {
    final channelRef = _channelDoc(workspaceId, channelId);
    final msgRef = _messagesCol(workspaceId, channelId).doc();
    final preview = (caption ?? '').trim().isEmpty ? '📷 Photo' : caption!.trim();

    await _db.runTransaction((tx) async {
      final wsSnap = await tx.get(_workspaceDoc(workspaceId));
      final memberUids =
          (wsSnap.data()?['memberUids'] as List?)?.cast<String>() ?? <String>[];

      tx.set(msgRef, {
        'senderUid': myUid,
        'type': 'image',
        'text': caption?.trim() ?? '',
        'mediaBase64': imageBase64,
        'sizeBytes': sizeBytes,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [myUid],
        'readBy': [myUid],
      });

      final unreadUpdates = <String, dynamic>{myUid: 0};
      for (final uid in memberUids) {
        if (uid != myUid) unreadUpdates[uid] = FieldValue.increment(1);
      }

      tx.set(channelRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          'id': msgRef.id,
          'senderUid': myUid,
          'text': preview,
          'type': 'image',
          'createdAt': FieldValue.serverTimestamp(),
        },
        'unread': unreadUpdates,
      }, SetOptions(merge: true));

      for (final uid in memberUids) {
        if (uid == myUid) continue;
        final notifRef = _db.collection('notifications').doc();
        tx.set(notifRef, {
          'type': 'channel_message',
          'toUid': uid,
          'fromUid': myUid,
          'workspaceId': workspaceId,
          'channelId': channelId,
          'messageId': msgRef.id,
          'title': 'New photo',
          'body': preview,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
    });
  }

  Future<void> markChannelRead({
    required String workspaceId,
    required String channelId,
    required String myUid,
    bool sendReadReceipts = true,
  }) async {
    await _channelDoc(workspaceId, channelId).set({
      'unread': {myUid: 0},
    }, SetOptions(merge: true));

    final snap = await _messagesCol(workspaceId, channelId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.set(
        d.reference,
        {
          'deliveredTo': FieldValue.arrayUnion([myUid]),
          if (sendReadReceipts) 'readBy': FieldValue.arrayUnion([myUid]),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> setTyping({
    required String workspaceId,
    required String channelId,
    required String myUid,
    required bool isTyping,
  }) async {
    await _typingDoc(workspaceId, channelId, myUid).set({
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<String>> watchTypingMemberUids({
    required String workspaceId,
    required String channelId,
    required String myUid,
  }) {
    return _channelDoc(workspaceId, channelId)
        .collection('typing')
        .snapshots()
        .map((snap) {
      return snap.docs
          .where((d) => d.id != myUid)
          .where((d) => (d.data()['isTyping'] as bool?) ?? false)
          .map((d) => d.id)
          .toList(growable: false);
    });
  }
}
