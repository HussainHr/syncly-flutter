import '../../domain/entities/app_user.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_data_source.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource _remote;

  UsersRepositoryImpl(this._remote);

  @override
  Future<List<AppUser>> getUsersPage({
    required int limit,
    String? searchTerm,
    String? startAfterUid,
  }) {
    return _remote.getUsersPage(
      limit: limit,
      searchTerm: searchTerm,
      startAfterUid: startAfterUid,
    );
  }

  @override
  Future<AppUser?> getUserByUid(String uid) => _remote.getUserByUid(uid);

  @override
  Stream<AppUser?> watchUserByUid(String uid) => _remote.watchUserByUid(uid);

  @override
  Future<void> updateMyProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
    String? photoBase64,
  }) {
    return _remote.updateMyProfile(
      uid: uid,
      displayName: displayName,
      bio: bio,
      photoUrl: photoUrl,
      photoBase64: photoBase64,
    );
  }

  @override
  Future<void> updateMyPrivacy({
    required String uid,
    String? privacyLastSeen,
    String? privacyOnline,
    String? privacyPhoto,
    String? privacyAbout,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
  }) {
    return _remote.updateMyPrivacy(
      uid: uid,
      privacyLastSeen: privacyLastSeen,
      privacyOnline: privacyOnline,
      privacyPhoto: privacyPhoto,
      privacyAbout: privacyAbout,
      readReceiptsEnabled: readReceiptsEnabled,
      typingIndicatorEnabled: typingIndicatorEnabled,
    );
  }
}

