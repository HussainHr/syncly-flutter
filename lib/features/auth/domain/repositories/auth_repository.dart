import 'package:firebase_auth/firebase_auth.dart' show User;

import '../entities/chat_user.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  Stream<bool> authTokenStateChanges();
  User? get currentFirebaseUser;

  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<User> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Future<ChatUser> upsertUserProfile({
    required User firebaseUser,
    String? displayName,
    String? photoUrl,
    bool? isOnline,
  });

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  });
}

