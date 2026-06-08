import '../../domain/entities/friend_request.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friends_remote_data_source.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource _remote;

  FriendsRepositoryImpl(this._remote);

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String myUid) =>
      _remote.watchIncoming(myUid);

  @override
  Stream<List<FriendRequest>> watchOutgoingRequests(String myUid) =>
      _remote.watchOutgoing(myUid);

  @override
  Stream<List<Friendship>> watchFriendships(String myUid) =>
      _remote.watchFriendships(myUid);

  @override
  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) {
    if (fromUid == toUid) return Future.value();
    return _remote.sendRequest(fromUid: fromUid, toUid: toUid);
  }

  @override
  Future<void> cancelFriendRequest({
    required String fromUid,
    required String toUid,
  }) {
    if (fromUid == toUid) return Future.value();
    return _remote.cancelRequest(fromUid: fromUid, toUid: toUid);
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String myUid,
  }) {
    return _remote.acceptRequest(requestId: requestId, myUid: myUid);
  }

  @override
  Future<void> rejectFriendRequest({
    required String requestId,
    required String myUid,
  }) async {
    // myUid is kept for consistency (we can enforce ownership later).
    await _remote.rejectRequest(requestId: requestId);
  }

  @override
  Future<void> unfriend({required String myUid, required String otherUid}) {
    if (myUid == otherUid) return Future.value();
    return _remote.unfriend(myUid: myUid, otherUid: otherUid);
  }

  @override
  Stream<bool> watchIsBlocked({
    required String blockerUid,
    required String blockedUid,
  }) {
    if (blockerUid == blockedUid) return Stream<bool>.value(false);
    return _remote.watchIsBlocked(blockerUid: blockerUid, blockedUid: blockedUid);
  }

  @override
  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  }) {
    if (blockerUid == blockedUid) return Future.value();
    return _remote.blockUser(blockerUid: blockerUid, blockedUid: blockedUid);
  }

  @override
  Future<void> unblockUser({
    required String blockerUid,
    required String blockedUid,
  }) {
    if (blockerUid == blockedUid) return Future.value();
    return _remote.unblockUser(blockerUid: blockerUid, blockedUid: blockedUid);
  }
}

