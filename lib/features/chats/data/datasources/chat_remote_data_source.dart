import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _db;

  ChatRemoteDataSource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  DocumentReference<Map<String, dynamic>> chatDoc(String chatId) => _chats.doc(chatId);

  CollectionReference<Map<String, dynamic>> messagesCol(String chatId) =>
      chatDoc(chatId).collection('messages');

  DocumentReference<Map<String, dynamic>> typingDoc(String chatId, String uid) =>
      chatDoc(chatId).collection('typing').doc(uid);

  static String directChatId(String uid1, String uid2) {
    final a = uid1.compareTo(uid2) <= 0 ? uid1 : uid2;
    final b = uid1.compareTo(uid2) <= 0 ? uid2 : uid1;
    return '${a}_$b';
  }

  Stream<List<ChatModel>> watchMyChats(String myUid) {
    // Note: ordering would require index; we sort locally by updatedAt.
    return _chats.where('members', arrayContains: myUid).snapshots().map((s) {
      final list = s.docs.map(ChatModel.fromDoc).toList(growable: false);
      DateTime activity(ChatModel c) => c.lastMessage?.createdAt ?? c.updatedAt;
      final sorted = [...list]..sort((a, b) => activity(b).compareTo(activity(a)));
      return sorted;
    });
  }

  Future<ChatModel> createOrGetDirectChat({
    required String myUid,
    required String otherUid,
  }) async {
    final chatId = directChatId(myUid, otherUid);
    final ref = chatDoc(chatId);

    final snap = await ref.get();
    if (snap.exists) {
      return ChatModel.fromDoc(snap);
    }

    final now = FieldValue.serverTimestamp();
    await ref.set({
      'type': 'direct',
      'members': [myUid, otherUid],
      'createdAt': now,
      'updatedAt': now,
      'unread': {myUid: 0, otherUid: 0},
    }, SetOptions(merge: true));

    final created = await ref.get();
    return ChatModel.fromDoc(created);
  }

  Stream<List<MessageModel>> watchMessages(String chatId, {int limit = 50}) {
    return messagesCol(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => MessageModel.fromDoc(chatId, d))
              .toList(growable: false),
        );
  }

  Future<MessageModel?> getMessageById({
    required String chatId,
    required String messageId,
  }) async {
    final snap = await messagesCol(chatId).doc(messageId).get();
    if (!snap.exists) return null;
    return MessageModel.fromDoc(chatId, snap);
  }

  Future<List<MessageModel>> getRecentMessages({
    required String chatId,
    int limit = 30,
  }) async {
    final snap = await messagesCol(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => MessageModel.fromDoc(chatId, d)).toList(growable: false);
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String myUid,
    required String text,
    String? messageId,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = chatDoc(chatId);
    final msgRef = messagesCol(chatId).doc(messageId);
    final notifRef = _db.collection('notifications').doc();

    await _db.runTransaction((tx) async {
      final chatSnap = await tx.get(chatRef);
      final members = (chatSnap.data()?['members'] as List?)?.cast<String>() ?? const <String>[];
      final otherUid = members.firstWhere((u) => u != myUid, orElse: () => '');

      tx.set(msgRef, {
        'senderUid': myUid,
        'type': 'text',
        'text': trimmed,
        'replyToMessageId': replyToMessageId,
        'replyToSenderUid': replyToSenderUid,
        'replyToText': replyToText,
        'replyToType': replyToType,
        'isForwarded': isForwarded,
        'forwardedFromUid': forwardedFromUid,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [myUid],
        'readBy': [myUid],
      });

      // update chat head
      tx.set(chatRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          'id': msgRef.id,
          'senderUid': myUid,
          'text': trimmed,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'unread': {
          myUid: 0,
          if (otherUid.isNotEmpty)
            otherUid: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      if (otherUid.isNotEmpty) {
        tx.set(notifRef, {
          'type': 'message',
          'toUid': otherUid,
          'fromUid': myUid,
          'chatId': chatId,
          'messageId': msgRef.id,
          'title': 'New message',
          'body': trimmed,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
    });
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String myUid,
    String? imageUrl,
    String? imageBase64,
    String? caption,
    required int? sizeBytes,
    required int? width,
    required int? height,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  }) async {
    if ((imageUrl == null || imageUrl.isEmpty) &&
        (imageBase64 == null || imageBase64.isEmpty)) {
      return;
    }
    final chatRef = chatDoc(chatId);
    final msgRef = messagesCol(chatId).doc();
    final notifRef = _db.collection('notifications').doc();

    await _db.runTransaction((tx) async {
      final chatSnap = await tx.get(chatRef);
      final members =
          (chatSnap.data()?['members'] as List?)?.cast<String>() ?? const <String>[];
      final otherUid = members.firstWhere((u) => u != myUid, orElse: () => '');

      tx.set(msgRef, {
        'senderUid': myUid,
        'type': 'image',
        'text': (caption ?? '').trim(),
        'mediaUrl': imageUrl,
        'mediaBase64': imageBase64,
        'mimeType': 'image/jpeg',
        'sizeBytes': sizeBytes,
        'width': width,
        'height': height,
        'replyToMessageId': replyToMessageId,
        'replyToSenderUid': replyToSenderUid,
        'replyToText': replyToText,
        'replyToType': replyToType,
        'isForwarded': isForwarded,
        'forwardedFromUid': forwardedFromUid,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [myUid],
        'readBy': [myUid],
      });

      tx.set(chatRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          'id': msgRef.id,
          'senderUid': myUid,
          'text': (caption ?? '').trim().isEmpty ? '📷 Photo' : (caption ?? '').trim(),
          'type': 'image',
          'mediaUrl': imageUrl,
          'mediaBase64': imageBase64,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'unread': {
          myUid: 0,
          if (otherUid.isNotEmpty) otherUid: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      if (otherUid.isNotEmpty) {
        final preview = (caption ?? '').trim().isEmpty ? '📷 Photo' : (caption ?? '').trim();
        tx.set(notifRef, {
          'type': 'message',
          'toUid': otherUid,
          'fromUid': myUid,
          'chatId': chatId,
          'messageId': msgRef.id,
          'title': 'New photo',
          'body': preview,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
    });
  }

  Future<void> sendFileMessage({
    required String chatId,
    required String myUid,
    String? fileUrl,
    String? fileBase64,
    required String fileName,
    required String? mimeType,
    required int? sizeBytes,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  }) async {
    if ((fileUrl == null || fileUrl.isEmpty) &&
        (fileBase64 == null || fileBase64.isEmpty)) {
      return;
    }
    final chatRef = chatDoc(chatId);
    final msgRef = messagesCol(chatId).doc();
    final notifRef = _db.collection('notifications').doc();

    await _db.runTransaction((tx) async {
      final chatSnap = await tx.get(chatRef);
      final members =
          (chatSnap.data()?['members'] as List?)?.cast<String>() ?? const <String>[];
      final otherUid = members.firstWhere((u) => u != myUid, orElse: () => '');

      tx.set(msgRef, {
        'senderUid': myUid,
        'type': 'file',
        'text': '',
        'mediaUrl': fileUrl,
        'mediaBase64': fileBase64,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'replyToMessageId': replyToMessageId,
        'replyToSenderUid': replyToSenderUid,
        'replyToText': replyToText,
        'replyToType': replyToType,
        'isForwarded': isForwarded,
        'forwardedFromUid': forwardedFromUid,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredTo': [myUid],
        'readBy': [myUid],
      });

      tx.set(chatRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': {
          'id': msgRef.id,
          'senderUid': myUid,
          'text': '📎 $fileName',
          'type': 'file',
          'mediaUrl': fileUrl,
          'mediaBase64': fileBase64,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'unread': {
          myUid: 0,
          if (otherUid.isNotEmpty) otherUid: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      if (otherUid.isNotEmpty) {
        tx.set(notifRef, {
          'type': 'message',
          'toUid': otherUid,
          'fromUid': myUid,
          'chatId': chatId,
          'messageId': msgRef.id,
          'title': 'New file',
          'body': '📎 $fileName',
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
    });
  }

  Future<void> markChatRead({
    required String chatId,
    required String myUid,
    bool sendReadReceipts = true,
  }) async {
    await chatDoc(chatId).set({
      'unread': {myUid: 0},
    }, SetOptions(merge: true));

    // Mark latest messages as read (best-effort, last 50)
    final snap = await messagesCol(chatId)
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
    required String chatId,
    required String myUid,
    required bool isTyping,
  }) async {
    await typingDoc(chatId, myUid).set({
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setStarred({
    required String chatId,
    required String messageId,
    required String myUid,
    required bool starred,
  }) async {
    final ref = messagesCol(chatId).doc(messageId);
    await ref.set(
      {
        'starredBy': starred
            ? FieldValue.arrayUnion([myUid])
            : FieldValue.arrayRemove([myUid]),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteForMe({
    required String chatId,
    required String messageId,
    required String myUid,
  }) async {
    final ref = messagesCol(chatId).doc(messageId);
    await ref.set(
      {
        'deletedFor': FieldValue.arrayUnion([myUid]),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteForEveryone({
    required String chatId,
    required String messageId,
    required String myUid,
  }) async {
    final chatRef = chatDoc(chatId);
    final msgRef = messagesCol(chatId).doc(messageId);

    await _db.runTransaction((tx) async {
      final msgSnap = await tx.get(msgRef);
      if (!msgSnap.exists) return;
      final data = msgSnap.data() ?? <String, dynamic>{};
      final senderUid = (data['senderUid'] as String?) ?? '';

      // IMPORTANT: Firestore transactions require all reads before all writes.
      final chatSnap = await tx.get(chatRef);
      final last = chatSnap.data()?['lastMessage'];
      final lastId = (last is Map) ? last['id']?.toString() : null;

      tx.set(
        msgRef,
        {
          'deletedForAll': true,
          'deletedBy': myUid,
          'deletedAt': FieldValue.serverTimestamp(),
          // Keep a minimal text for old clients and for chat heads.
          'text': 'Message deleted',
          // Remove heavy fields properly.
          'mediaUrl': FieldValue.delete(),
          'mediaBase64': FieldValue.delete(),
          'fileName': FieldValue.delete(),
          'mimeType': FieldValue.delete(),
          'sizeBytes': FieldValue.delete(),
          'width': FieldValue.delete(),
          'height': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      if (lastId == messageId) {
        tx.set(
          chatRef,
          {
            'lastMessage': {
              'id': messageId,
              'senderUid': senderUid.isNotEmpty ? senderUid : myUid,
              'text': 'Message deleted',
              'createdAt': FieldValue.serverTimestamp(),
              'type': 'text',
            },
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Stream<bool> watchTyping({
    required String chatId,
    required String otherUid,
  }) {
    return typingDoc(chatId, otherUid).snapshots().map((d) {
      final data = d.data();
      if (data == null) return false;
      final isTyping = (data['isTyping'] as bool?) ?? false;
      return isTyping;
    });
  }
}

