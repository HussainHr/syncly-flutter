import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/friends/domain/entities/friend_request.dart';
import 'package:syncly/features/friends/domain/entities/friendship.dart';
import 'package:syncly/features/friends/presentation/providers/friends_streams.dart';

enum RelationshipStatus {
  blocked,
  friends,
  incomingRequest,
  outgoingRequest,
  none,
}

final relationshipProvider =
    Provider.family<RelationshipStatus, String>((ref, otherUid) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return RelationshipStatus.none;

  final isBlocked = ref.watch(isBlockedProvider(otherUid)).valueOrNull ?? false;
  if (isBlocked) return RelationshipStatus.blocked;

  final friends = ref.watch(friendshipsProvider).valueOrNull ?? const <Friendship>[];
  final isFriend = friends.any((f) => f.uidA == otherUid || f.uidB == otherUid);
  if (isFriend) return RelationshipStatus.friends;

  final incoming = ref.watch(incomingRequestsProvider).valueOrNull ?? const <FriendRequest>[];
  final hasIncoming = incoming.any((r) => r.fromUid == otherUid && r.toUid == me.uid);
  if (hasIncoming) return RelationshipStatus.incomingRequest;

  final outgoing = ref.watch(outgoingRequestsProvider).valueOrNull ?? const <FriendRequest>[];
  final hasOutgoing = outgoing.any((r) => r.toUid == otherUid && r.fromUid == me.uid);
  if (hasOutgoing) return RelationshipStatus.outgoingRequest;

  return RelationshipStatus.none;
});

