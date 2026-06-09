import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/channel_model.dart';
import '../models/workspace_member_model.dart';
import '../models/workspace_model.dart';

class WorkspacesRemoteDataSource {
  final FirebaseFirestore _db;
  final Random _random;

  WorkspacesRemoteDataSource({
    FirebaseFirestore? db,
    Random? random,
  })  : _db = db ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  CollectionReference<Map<String, dynamic>> get _workspaces =>
      _db.collection('workspaces');

  DocumentReference<Map<String, dynamic>> _workspaceDoc(String workspaceId) =>
      _workspaces.doc(workspaceId);

  CollectionReference<Map<String, dynamic>> _channelsCol(String workspaceId) =>
      _workspaceDoc(workspaceId).collection('channels');

  CollectionReference<Map<String, dynamic>> _membersCol(String workspaceId) =>
      _workspaceDoc(workspaceId).collection('members');

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<String> _uniqueInviteCode() async {
    for (var i = 0; i < 12; i++) {
      final code = _generateInviteCode();
      final snap = await _workspaces
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return code;
    }
    throw StateError('Failed to generate a unique invite code.');
  }

  static String _normalizeChannelName(String name) {
    final trimmed = name.trim().toLowerCase();
    return trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  }

  Stream<List<WorkspaceModel>> watchMyWorkspaces(String myUid) {
    return _workspaces
        .where('memberUids', arrayContains: myUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(WorkspaceModel.fromDoc).toList(growable: false);
      final sorted = [...list]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sorted;
    });
  }

  Stream<WorkspaceModel?> watchWorkspace(String workspaceId) {
    return _workspaceDoc(workspaceId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WorkspaceModel.fromDoc(doc);
    });
  }

  Stream<List<ChannelModel>> watchChannels(String workspaceId) {
    return _channelsCol(workspaceId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ChannelModel.fromDoc(workspaceId: workspaceId, doc: d))
          .toList(growable: false);
      final sorted = [...list]..sort((a, b) {
          final aTime = a.lastMessage?.createdAt ?? a.updatedAt;
          final bTime = b.lastMessage?.createdAt ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });
      return sorted;
    });
  }

  Future<WorkspaceMemberModel?> getMyMembership({
    required String workspaceId,
    required String myUid,
  }) async {
    final snap = await _membersCol(workspaceId).doc(myUid).get();
    if (!snap.exists) return null;
    return WorkspaceMemberModel.fromDoc(workspaceId: workspaceId, doc: snap);
  }

  Future<WorkspaceModel> createWorkspace({
    required String name,
    required String createdBy,
    required String creatorDisplayName,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Workspace name is required.');
    }

    final workspaceRef = _workspaces.doc();
    final inviteCode = await _uniqueInviteCode();
    final generalChannelRef = _channelsCol(workspaceRef.id).doc();
    final memberRef = _membersCol(workspaceRef.id).doc(createdBy);
    final now = FieldValue.serverTimestamp();

    // Workspace + member in one transaction. Channel is created after commit
    // because security rules read committed state (not pending txn writes).
    await _db.runTransaction((tx) async {
      tx.set(workspaceRef, {
        'name': trimmedName,
        'inviteCode': inviteCode,
        'createdBy': createdBy,
        'memberUids': [createdBy],
        'memberCount': 1,
        'createdAt': now,
        'updatedAt': now,
      });

      tx.set(memberRef, {
        'uid': createdBy,
        'displayName': creatorDisplayName,
        'role': 'owner',
        'joinedAt': now,
      });
    });

    await generalChannelRef.set({
      'name': 'general',
      'type': 'text',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unread': <String, int>{},
    });

    final created = await workspaceRef.get();
    return WorkspaceModel.fromDoc(created);
  }

  Future<WorkspaceModel> joinWorkspace({
    required String inviteCode,
    required String myUid,
    required String myDisplayName,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw ArgumentError('Invite code is required.');
    }

    final query = await _workspaces
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Invalid invite code.');
    }

    final workspaceDoc = query.docs.first;
    final workspaceRef = workspaceDoc.reference;
    final memberRef = _membersCol(workspaceDoc.id).doc(myUid);
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      final wsSnap = await tx.get(workspaceRef);
      if (!wsSnap.exists) {
        throw StateError('Workspace no longer exists.');
      }

      final memberSnap = await tx.get(memberRef);
      final memberUids =
          (wsSnap.data()?['memberUids'] as List?)?.cast<String>() ?? <String>[];
      final alreadyListed = memberUids.contains(myUid);
      final memberDocExists = memberSnap.exists;

      if (alreadyListed && memberDocExists) return;

      if (!memberDocExists) {
        tx.set(memberRef, {
          'uid': myUid,
          'displayName': myDisplayName,
          'role': 'member',
          'joinedAt': now,
        });
      }

      if (!alreadyListed) {
        tx.update(workspaceRef, {
          'memberUids': FieldValue.arrayUnion([myUid]),
          'memberCount': FieldValue.increment(1),
          'updatedAt': now,
        });
      }
    });

    final updated = await workspaceRef.get();
    return WorkspaceModel.fromDoc(updated);
  }

  Future<ChannelModel> createChannel({
    required String workspaceId,
    required String name,
    required String createdBy,
  }) async {
    final normalized = _normalizeChannelName(name);
    if (normalized.isEmpty) {
      throw ArgumentError('Channel name is required.');
    }

    final existing = await _channelsCol(workspaceId)
        .where('name', isEqualTo: normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError('A channel with this name already exists.');
    }

    final channelRef = _channelsCol(workspaceId).doc();
    final now = FieldValue.serverTimestamp();

    await channelRef.set({
      'name': normalized,
      'type': 'text',
      'createdBy': createdBy,
      'createdAt': now,
      'updatedAt': now,
      'unread': <String, int>{},
    });
    await _workspaceDoc(workspaceId).update({'updatedAt': now});

    final created = await channelRef.get();
    return ChannelModel.fromDoc(workspaceId: workspaceId, doc: created);
  }
}
