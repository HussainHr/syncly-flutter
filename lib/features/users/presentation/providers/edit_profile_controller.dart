import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:syncly/features/users/domain/repositories/users_repository.dart';
import 'package:syncly/features/users/presentation/providers/users_providers.dart';

@immutable
class EditProfileState {
  final bool saving;
  final String? error;

  const EditProfileState({required this.saving, this.error});

  const EditProfileState.idle() : saving = false, error = null;

  EditProfileState copyWith({bool? saving, String? error}) {
    return EditProfileState(
      saving: saving ?? this.saving,
      error: error,
    );
  }
}

final editProfileControllerProvider =
    StateNotifierProvider<EditProfileController, EditProfileState>((ref) {
  final repo = ref.watch(usersRepositoryProvider);
  return EditProfileController(repo);
});

class EditProfileController extends StateNotifier<EditProfileState> {
  final UsersRepository _repo;

  EditProfileController(this._repo) : super(const EditProfileState.idle());

  static const int _maxAvatarBytes = 500 * 1024; // keep safely under Firestore 1MB doc limit

  Future<bool> save({
    required String uid,
    required String displayName,
    required String bio,
    String? localAvatarPath,
  }) async {
    state = state.copyWith(saving: true, error: null);
    try {
      String? photoBase64;
      if (localAvatarPath != null && localAvatarPath.isNotEmpty) {
        final bytes = await _readAndCompressAvatar(localAvatarPath);
        if (bytes.length > _maxAvatarBytes) {
          throw Exception(
            'Avatar is too large. Please choose a smaller image (max ${( _maxAvatarBytes / 1024).round()}KB).',
          );
        }
        photoBase64 = base64Encode(bytes);
      }

      await _repo.updateMyProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
        // keep photoUrl untouched; use base64 to avoid paid Storage
        photoBase64: photoBase64,
      );

      // Keep FirebaseAuth profile in sync for convenience.
      final me = FirebaseAuth.instance.currentUser;
      if (me != null && me.uid == uid) {
        if (displayName.trim().isNotEmpty) await me.updateDisplayName(displayName.trim());
        // Can't store base64 in FirebaseAuth photoURL. Keep as-is.
      }

      state = state.copyWith(saving: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Future<List<int>> _readAndCompressAvatar(String path) async {
    final file = File(path);
    final raw = await file.readAsBytes();

    // First pass: try compress reasonably.
    final compressed = await FlutterImageCompress.compressWithList(
      raw,
      quality: 80,
      minWidth: 512,
      minHeight: 512,
      format: CompressFormat.jpeg,
    );

    if (compressed.isNotEmpty) return compressed;
    return raw;
  }
}

