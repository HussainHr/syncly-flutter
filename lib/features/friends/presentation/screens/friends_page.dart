import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/core/widgets/skeletons/list_tile_skeleton.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/friends/presentation/providers/friends_providers.dart';
import 'package:syncly/features/friends/presentation/providers/friends_streams.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

class FriendsPage extends ConsumerWidget {
  final bool embedded;

  const FriendsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendshipsProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    final body = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                unselectedLabelStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                tabs: [
                  Tab(
                    text: 'Friends',
                    icon: friendsAsync.maybeWhen(
                      data: (d) => d.isNotEmpty
                          ? Badge(label: Text('${d.length}'), child: const Icon(Icons.people_outline))
                          : const Icon(Icons.people_outline),
                      orElse: () => const Icon(Icons.people_outline),
                    ),
                  ),
                  Tab(
                    text: 'Incoming',
                    icon: incomingAsync.maybeWhen(
                      data: (d) => d.isNotEmpty
                          ? Badge(label: Text('${d.length}'), child: const Icon(Icons.inbox_outlined))
                          : const Icon(Icons.inbox_outlined),
                      orElse: () => const Icon(Icons.inbox_outlined),
                    ),
                  ),
                  Tab(
                    text: 'Outgoing',
                    icon: outgoingAsync.maybeWhen(
                      data: (d) => d.isNotEmpty
                          ? Badge(
                        label: Text('${d.length}'),
                        child: const Icon(Icons.outbox_outlined),
                      )
                          : const Icon(Icons.outbox_outlined),
                      orElse: () => const Icon(Icons.outbox_outlined),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FriendsList(),
                _IncomingList(),
                _OutgoingList(),
              ],
            ),
          ),
        ],
      ),
    );

    if (embedded) return SafeArea(child: body);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: SafeArea(child: body),
    );
  }
}

class _FriendsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendshipsProvider);
    final me = ref.watch(currentUserProvider);
    return friendsAsync.when(
      loading: () => const ListSkeleton(itemCount: 10),
      error: (e, _) => Center(child: Text('Failed: $e'),),
      data: (friends) {
        if (friends.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              EmptyState(
                icon: Icons.people_outline,
                title: 'No friends yet',
                message: 'Send requests from the Users tab to add friends.',
              ),
            ],
          );
        }

        return ListView.separated(
          itemCount: friends.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final f = friends[i];
            final myUid = me?.uid ?? '';
            final otherUid = f.uidA == myUid ? f.uidB : f.uidA;
            final other = ref.watch(userProfileProvider(otherUid)).valueOrNull;
            return ListTile(
              onTap: () => context.push('/users/$otherUid'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: GestureDetector(
                onTap: other == null
                    ? null
                    : () => showAvatarViewer(
                          context,
                          name: other.displayName,
                          photoUrl: other.photoUrl,
                          photoBase64: other.photoBase64,
                        ),
                child: CustomAvatar(
                  height: 46,
                  width: 46,
                  name: other?.displayName ?? otherUid,
                  image: other?.photoUrl ?? '',
                  base64: other?.photoBase64,
                  network: (other?.photoUrl ?? '').isNotEmpty,
                ),
              ),
              title: Text(other?.displayName ?? otherUid),
              subtitle: Text(other?.bio ?? ''),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }
}

class _IncomingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final me = ref.watch(currentUserProvider);
    final repo = ref.watch(friendsRepositoryProvider);
    return incomingAsync.when(
      loading: () => const ListSkeleton(itemCount: 8, showTrailing: false),
      error: (e, _) => Center(child: Text('Failed: $e')),
      data: (reqs) {
        if (reqs.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No incoming requests',
                message: 'When someone sends you a request, it will appear here.',
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: reqs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = reqs[i];
            return ListTile(
              onTap: () => context.push('/users/${r.fromUid}'),
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text('Request from ${r.fromUid}'),
              subtitle: const Text('Accept or reject'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Reject',
                    onPressed: me == null
                        ? null
                        : () => repo.rejectFriendRequest(
                      requestId: r.id,
                      myUid: me.uid,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                  IconButton.filled(
                    tooltip: 'Accept',
                    onPressed: me == null
                        ? null
                        : () => repo.acceptFriendRequest(
                      requestId: r.id,
                      myUid: me.uid,
                    ),
                    icon: const Icon(Icons.done),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OutgoingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final me = ref.watch(currentUserProvider);
    final repo = ref.watch(friendsRepositoryProvider);
    return outgoingAsync.when(
      loading: () => const ListSkeleton(itemCount: 8, showTrailing: false),
      error: (e, stack) {
        debugPrint('Incoming Requests Error: $e');
        debugPrint('StackTrace: $stack');
        return Center(child: Text('Failed: $e'));},
      data: (reqs) {
        if (reqs.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              EmptyState(
                icon: Icons.outbox_outlined,
                title: 'No outgoing requests',
                message: 'Requests you send will appear here until accepted.',
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: reqs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = reqs[i];
            return ListTile(
              onTap: () => context.push('/users/${r.toUid}'),
              leading: const Icon(Icons.outbox_outlined),
              title: Text('Requested ${r.toUid}'),
              subtitle: const Text('Pending'),
              trailing: TextButton(
                onPressed: me == null
                    ? null
                    : () => repo.cancelFriendRequest(fromUid: me.uid, toUid: r.toUid),
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
    );
  }
}

