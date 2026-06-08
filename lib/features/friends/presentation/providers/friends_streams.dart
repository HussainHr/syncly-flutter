import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/friends/domain/entities/friend_request.dart';
import 'package:syncly/features/friends/domain/entities/friendship.dart';
import 'package:syncly/features/friends/presentation/providers/friends_providers.dart';

final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream.empty();
  return ref.watch(friendsRepositoryProvider).watchIncomingRequests(me.uid);
});

final outgoingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream.empty();
  return ref.watch(friendsRepositoryProvider).watchOutgoingRequests(me.uid);
});

final friendshipsProvider = StreamProvider<List<Friendship>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream.empty();
  return ref.watch(friendsRepositoryProvider).watchFriendships(me.uid);
});

final isBlockedProvider = StreamProvider.family<bool, String>((ref, otherUid) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const Stream<bool>.empty();
  return ref
      .watch(friendsRepositoryProvider)
      .watchIsBlocked(blockerUid: me.uid, blockedUid: otherUid);
});

