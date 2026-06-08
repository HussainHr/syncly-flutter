import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/repositories/auth_repository.dart';

@immutable
class AuthUiState {
  final bool loading;
  final String? error;

  const AuthUiState({required this.loading, this.error});

  const AuthUiState.idle() : loading = false, error = null;

  AuthUiState copyWith({bool? loading, String? error}) {
    return AuthUiState(
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

final authUiControllerProvider =
    StateNotifierProvider<AuthUiController, AuthUiState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthUiController(repo);
});

class AuthUiController extends StateNotifier<AuthUiState> {
  final AuthRepository _repo;

  AuthUiController(this._repo) : super(const AuthUiState.idle());

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please try again.';
      case 'google-sign-in-cancelled':
        return 'Google sign-in cancelled.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signInWithEmail(email: email.trim(), password: password);
      state = state.copyWith(loading: false, error: null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(loading: false, error: _mapFirebaseAuthError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signUpWithEmail(
        displayName: name.trim(),
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(loading: false, error: null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(loading: false, error: _mapFirebaseAuthError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signInWithGoogle();
      state = state.copyWith(loading: false, error: null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(loading: false, error: _mapFirebaseAuthError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> sendResetLink({required String email}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.sendPasswordResetEmail(email: email.trim());
      state = state.copyWith(loading: false, error: null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(loading: false, error: _mapFirebaseAuthError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to send reset link. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() => _repo.signOut();

  void clearError() => state = state.copyWith(error: null);
}

