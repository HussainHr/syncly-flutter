import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/utils/privacy.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/core/widgets/skeletons/list_tile_skeleton.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/features/chats/presentation/providers/chat_streams.dart';
import 'package:syncly/features/friends/presentation/providers/relationship_provider.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

class ChatsPage extends ConsumerWidget {
  final bool embedded;

  const ChatsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(myChatsProvider);

    final body = chatsAsync.when(
      loading: () => const ListSkeleton(itemCount: 10),
      error: (e, _) => Center(child: Text('Failed: $e')),
      data: (chats) {
        if (me == null) {
          return const Center(child: Text('Not signed in'));
        }
        if (chats.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No chats yet',
                message: 'Start a conversation from the Users tab.',
              ),
            ],
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = chats[i];
            final otherUid =
                c.members.firstWhere((u) => u != me.uid, orElse: () => '');
            final other = otherUid.isEmpty
                ? null
                : ref.watch(userProfileProvider(otherUid)).valueOrNull;
            final rel =
                otherUid.isEmpty ? RelationshipStatus.none : ref.watch(relationshipProvider(otherUid));
            final unread = c.unread[me.uid] ?? 0;

            final time = DateFormat('hh:mm a').format(c.updatedAt);
            final subtitleAsync = ref.watch(
              chatSubtitleProvider((chatId: c.id, myUid: me.uid, last: c.lastMessage)),
            );
            return ListTile(
              onTap: () => context.push('/chats/${c.id}?otherUid=$otherUid'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: GestureDetector(
                onTap: other == null
                    ? null
                    : () => showAvatarViewer(
                          context,
                          name: other.displayName,
                          photoUrl: canSeeByAudience(
                            audience: other.privacyPhoto,
                            isMe: me.uid == other.uid,
                            relationship: rel,
                          )
                              ? other.photoUrl
                              : null,
                          photoBase64: canSeeByAudience(
                            audience: other.privacyPhoto,
                            isMe: me.uid == other.uid,
                            relationship: rel,
                          )
                              ? other.photoBase64
                              : null,
                        ),
                child: CustomAvatar(
                  height: 46,
                  width: 46,
                  name: other?.displayName ?? otherUid,
                  image: other == null
                      ? ''
                      : (canSeeByAudience(
                              audience: other.privacyPhoto,
                              isMe: me.uid == other.uid,
                              relationship: rel,
                            )
                          ? (other.photoUrl ?? '')
                          : ''),
                  base64: other == null
                      ? null
                      : (canSeeByAudience(
                              audience: other.privacyPhoto,
                              isMe: me.uid == other.uid,
                              relationship: rel,
                            )
                          ? other.photoBase64
                          : null),
                  network: other != null &&
                      canSeeByAudience(
                        audience: other.privacyPhoto,
                        isMe: me.uid == other.uid,
                        relationship: rel,
                      ) &&
                      (other.photoUrl ?? '').isNotEmpty,
                ),
              ),
              title: Text(
                other?.displayName ?? otherUid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
                    ),
              ),
              subtitle: Text(
                subtitleAsync.valueOrNull ?? (c.lastMessage?.text ?? 'Tap to open'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  if (unread > 0)
                    Badge(
                      label: Text('$unread'),
                      largeSize: 18,
                      child: const SizedBox(width: 1, height: 1),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (embedded) return SafeArea(child: body);
    return Scaffold(appBar: AppBar(title: const Text('Chats')), body: SafeArea(child: body));
  }
}

