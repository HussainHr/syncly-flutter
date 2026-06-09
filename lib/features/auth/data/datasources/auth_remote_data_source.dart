import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/user_role.dart';
import '../models/chat_user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  Stream<bool> authTokenStateChanges() =>
      _auth.idTokenChanges().map((u) => u != null);
  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw FirebaseAuthException(code: 'no-user');
    return res.user!;
  }

  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw FirebaseAuthException(code: 'no-user');
    return res.user!;
  }

  Future<User> signInWithGoogle() async {
    // Prefer Firebase native provider flow (more reliable on Android/iOS).
    // Falls back to google_sign_in if not supported on the current platform.
    UserCredential res;
    try {
      res = await _auth.signInWithProvider(GoogleAuthProvider());
    } catch (_) {
      await GoogleSignIn.instance.initialize();
      final acct = await GoogleSignIn.instance.authenticate();
      final auth = acct.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      res = await _auth.signInWithCredential(credential);
    }
    if (res.user == null) throw FirebaseAuthException(code: 'no-user');
    return res.user!;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<ChatUserModel> upsertUserProfile({
    required User firebaseUser,
    String? displayName,
    String? photoUrl,
    bool? isOnline,
    UserRole? role,
  }) async {
    final now = DateTime.now();
    final ref = _userDoc(firebaseUser.uid);
    final snap = await ref.get();

    final existing = snap.data();
    final createdAt = existing?['createdAt'] is Timestamp
        ? (existing!['createdAt'] as Timestamp).toDate()
        : now;

    final model = ChatUserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: displayName ?? firebaseUser.displayName,
      photoUrl: photoUrl ?? firebaseUser.photoURL,
      createdAt: createdAt,
      updatedAt: now,
      lastSeenAt: now,
      isOnline: isOnline ?? true,
    );

    final map = model.toFirestore();
    final normalizedName = (model.displayName ?? '').trim();
    if (normalizedName.isNotEmpty) {
      map['displayNameLowercase'] = normalizedName.toLowerCase();
    }
    map.putIfAbsent('bio', () => '');
    if (role != null) {
      map['role'] = role.toFirestore();
    }
    await ref.set(map, SetOptions(merge: true));
    return model;
  }

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await _userDoc(uid).set({
      'isOnline': isOnline,
      'lastSeenAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}

