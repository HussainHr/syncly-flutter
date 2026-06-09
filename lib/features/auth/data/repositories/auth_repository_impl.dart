import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException, User;

import '../../domain/entities/chat_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Stream<User?> authStateChanges() => _remote.authStateChanges();

  @override
  Stream<bool> authTokenStateChanges() => _remote.authTokenStateChanges();

  @override
  User? get currentFirebaseUser => _remote.currentUser;

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signInWithEmail(email: email, password: password);
      try {
        await upsertUserProfile(firebaseUser: user, isOnline: true);
      } catch (_) {
        // Firestore may not be configured yet; don't block auth.
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final user = await _remote.signUpWithEmail(email: email, password: password);
      await user.updateDisplayName(displayName);
      await _upsertProfileWithRetry(
        firebaseUser: user,
        displayName: displayName,
        isOnline: true,
        role: role,
      );
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> _upsertProfileWithRetry({
    required User firebaseUser,
    String? displayName,
    String? photoUrl,
    bool? isOnline,
    UserRole? role,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await firebaseUser.getIdToken(true);
        await upsertUserProfile(
          firebaseUser: firebaseUser,
          displayName: displayName,
          photoUrl: photoUrl,
          isOnline: isOnline,
          role: role,
        );
        return;
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }
    }
    throw lastError ?? StateError('Failed to save user profile.');
  }

  @override
  Future<User> signInWithGoogle() async {
    final user = await _remote.signInWithGoogle();
    try {
      await upsertUserProfile(firebaseUser: user, isOnline: true);
    } catch (_) {
      // Firestore may not be configured yet; don't block auth.
    }
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _remote.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    final uid = currentFirebaseUser?.uid;
    if (uid != null) {
      try {
        await setOnlineStatus(uid: uid, isOnline: false);
      } catch (_) {
        // Don't block sign-out if Firestore isn't ready.
      }
    }
    await _remote.signOut();
  }

  @override
  Future<ChatUser> upsertUserProfile({
    required User firebaseUser,
    String? displayName,
    String? photoUrl,
    bool? isOnline,
    UserRole? role,
  }) {
    return _remote.upsertUserProfile(
      firebaseUser: firebaseUser,
      displayName: displayName,
      photoUrl: photoUrl,
      isOnline: isOnline,
      role: role,
    );
  }

  @override
  Future<void> setOnlineStatus({required String uid, required bool isOnline}) {
    return _remote.setOnlineStatus(uid: uid, isOnline: isOnline);
  }
}

