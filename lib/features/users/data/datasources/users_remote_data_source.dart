import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_model.dart';

class UsersRemoteDataSource {
  final FirebaseFirestore _db;

  UsersRemoteDataSource({
    FirebaseFirestore? db,
  })  : _db = db ?? FirebaseFirestore.instance,
        super();

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Future<List<AppUserModel>> getUsersPage({
    required int limit,
    String? searchTerm,
    String? startAfterUid,
  }) async {
    Query<Map<String, dynamic>> q = _users;

    final term = (searchTerm ?? '').trim().toLowerCase();
    if (term.isNotEmpty) {
      // Prefix search over a normalized field.
      q = q
          .orderBy('displayNameLowercase')
          .startAt([term])
          .endAt(['$term\uf8ff']);
    } else {
      q = q.orderBy('updatedAt', descending: true);
    }

    if (startAfterUid != null && startAfterUid.isNotEmpty) {
      final startDoc = await _users.doc(startAfterUid).get();
      if (startDoc.exists) {
        q = q.startAfterDocument(startDoc);
      }
    }

    final snap = await q.limit(limit).get();
    return snap.docs
        .map((d) => AppUserModel.fromFirestore(d.data(), uid: d.id))
        .toList(growable: false);
  }

  Future<AppUserModel?> getUserByUid(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return AppUserModel.fromFirestore(data, uid: snap.id);
  }

  Future<void> updateMyProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
    String? photoBase64,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) {
      final trimmed = displayName.trim();
      payload['displayName'] = trimmed;
      payload['displayNameLowercase'] = trimmed.toLowerCase();
    }
    if (bio != null) payload['bio'] = bio.trim();
    if (photoUrl != null) payload['photoUrl'] = photoUrl;
    if (photoBase64 != null) payload['photoBase64'] = photoBase64;

    await _users.doc(uid).set(payload, SetOptions(merge: true));
  }

  Future<void> updateMyPrivacy({
    required String uid,
    String? privacyLastSeen,
    String? privacyOnline,
    String? privacyPhoto,
    String? privacyAbout,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (privacyLastSeen != null) payload['privacyLastSeen'] = privacyLastSeen;
    if (privacyOnline != null) payload['privacyOnline'] = privacyOnline;
    if (privacyPhoto != null) payload['privacyPhoto'] = privacyPhoto;
    if (privacyAbout != null) payload['privacyAbout'] = privacyAbout;
    if (readReceiptsEnabled != null) payload['readReceiptsEnabled'] = readReceiptsEnabled;
    if (typingIndicatorEnabled != null) {
      payload['typingIndicatorEnabled'] = typingIndicatorEnabled;
    }
    await _users.doc(uid).set(payload, SetOptions(merge: true));
  }
}

