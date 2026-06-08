import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:syncly/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:syncly/features/auth/domain/repositories/auth_repository.dart'
    as feature;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final feature.AuthRepository _repo;

  AuthRepository({feature.AuthRepository? repo})
      : _repo = repo ?? AuthRepositoryImpl(AuthRemoteDataSource());

  User? get currentUser => _repo.currentFirebaseUser;

  Stream<User?> authStateChanges() => _repo.authStateChanges();

  /// Used by `GoRouterRefreshStream` to re-evaluate redirects when auth changes.
  Stream<bool> authTokenStateChanges() =>
      _repo.authTokenStateChanges();

  Future<bool> isAuthenticated() async => currentUser != null;

  // ---- Auth actions (used by presentation) ----
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _repo.signInWithEmail(email: email, password: password);

  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _repo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

  Future<User> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email}) =>
      _repo.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _repo.signOut();
}

