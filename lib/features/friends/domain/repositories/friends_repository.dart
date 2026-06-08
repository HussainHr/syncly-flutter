import '../entities/friend_request.dart';
import '../entities/friendship.dart';

abstract class FriendsRepository {
  Stream<List<FriendRequest>> watchIncomingRequests(String myUid);
  Stream<List<FriendRequest>> watchOutgoingRequests(String myUid);
  Stream<List<Friendship>> watchFriendships(String myUid);

  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  });

  Future<void> cancelFriendRequest({
    required String fromUid,
    required String toUid,
  });

  Future<void> acceptFriendRequest({
    required String requestId,
    required String myUid,
  });

  Future<void> rejectFriendRequest({
    required String requestId,
    required String myUid,
  });

  Future<void> unfriend({
    required String myUid,
    required String otherUid,
  });

  Stream<bool> watchIsBlocked({
    required String blockerUid,
    required String blockedUid,
  });

  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  });

  Future<void> unblockUser({
    required String blockerUid,
    required String blockedUid,
  });
}

