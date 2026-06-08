import '../entities/app_user.dart';

abstract class UsersRepository {
  Future<List<AppUser>> getUsersPage({
    required int limit,
    String? searchTerm,
    String? startAfterUid,
  });

  Future<AppUser?> getUserByUid(String uid);

  Future<void> updateMyProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
    String? photoBase64,
  });

  Future<void> updateMyPrivacy({
    required String uid,
    String? privacyLastSeen,
    String? privacyOnline,
    String? privacyPhoto,
    String? privacyAbout,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
  });
}

