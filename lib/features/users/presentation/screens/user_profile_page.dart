import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/core/widgets/confirm_action_sheet.dart';
import 'package:syncly/core/widgets/skeletons/profile_skeleton.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/core/utils/privacy.dart';
import 'package:syncly/features/chats/presentation/providers/chat_providers.dart';
import 'package:syncly/features/friends/presentation/providers/friends_providers.dart';
import 'package:syncly/features/friends/presentation/providers/friends_streams.dart';
import 'package:syncly/features/friends/presentation/providers/relationship_provider.dart';
import 'package:syncly/features/settings/presentation/providers/settings_controller.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

class UserProfilePage extends ConsumerWidget {
  final String uid;

  const UserProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final isMe = me?.uid == uid;
    final settings = ref.watch(settingsControllerProvider);
    final relationship = isMe ? null : ref.watch(relationshipProvider(uid));

    final asyncUser = ref.watch(userProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isMe ? 'My profile' : 'Profile'),
        actions: [
          if (isMe)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => context.push('/edit-profile'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: asyncUser.when(
          loading: () => const ProfileSkeleton(),
          error: (e, _) => Center(child: Text('Failed: $e')),
          data: (u) {
            if (u == null) return const Center(child: Text('User not found'));
            final lastSeen = u.lastSeenAt == null
                ? null
                : DateFormat('dd MMM, hh:mm a').format(u.lastSeenAt!);

            final rel = relationship ?? RelationshipStatus.none;
            final canSeePhoto = isMe ||
                canSeeByAudience(
                  audience: u.privacyPhoto,
                  isMe: isMe,
                  relationship: rel,
                );
            final canSeeAbout = isMe ||
                canSeeByAudience(
                  audience: u.privacyAbout,
                  isMe: isMe,
                  relationship: rel,
                );
            final canSeeOnline = isMe ||
                canSeeByAudience(
                  audience: u.privacyOnline,
                  isMe: isMe,
                  relationship: rel,
                );
            final canSeeLastSeen = isMe ||
                canSeeByAudience(
                  audience: u.privacyLastSeen,
                  isMe: isMe,
                  relationship: rel,
                );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => showAvatarViewer(
                            context,
                            name: u.displayName,
                            photoUrl: canSeePhoto ? u.photoUrl : null,
                            photoBase64: canSeePhoto ? u.photoBase64 : null,
                          ),
                          child: CustomAvatar(
                            height: 96,
                            width: 96,
                            name: u.displayName,
                            image: canSeePhoto ? (u.photoUrl ?? '') : '',
                            base64: canSeePhoto ? u.photoBase64 : null,
                            network: canSeePhoto && (u.photoUrl ?? '').isNotEmpty,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          u.displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isMe && settings.showMyEmail
                              ? u.email
                              : (!canSeeAbout
                                  ? 'About hidden'
                                  : (u.bio.isNotEmpty ? u.bio : 'No bio yet')),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _Pill(
                              icon: u.isOnline ? Icons.circle : Icons.schedule,
                              label: !canSeeOnline
                                  ? 'Status hidden'
                                  : (u.isOnline
                                      ? 'Online'
                                      : (!canSeeLastSeen
                                          ? 'Offline'
                                          : (lastSeen == null
                                              ? 'Offline'
                                              : 'Last seen $lastSeen'))),
                            ),
                            _Pill(
                              icon: Icons.badge_outlined,
                              label: 'UID • ${u.uid.substring(0, u.uid.length.clamp(0, 6))}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!isMe) ...[
                    _RelationshipActions(otherUid: uid, status: relationship!),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: (canSeeOnline && u.isOnline) ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                !canSeeOnline
                                    ? 'Status hidden'
                                    : (u.isOnline
                                        ? 'Online'
                                        : (!canSeeLastSeen
                                            ? 'Offline'
                                            : (lastSeen == null
                                                ? 'Offline'
                                                : 'Last seen $lastSeen'))),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            !canSeeAbout
                                ? 'This user has hidden their about.'
                                : (u.bio.isEmpty ? 'No bio yet.' : u.bio),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipActions extends ConsumerWidget {
  final String otherUid;
  final RelationshipStatus status;

  const _RelationshipActions({required this.otherUid, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const SizedBox.shrink();

    final repo = ref.watch(friendsRepositoryProvider);
    final incoming = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    final outgoing = ref.watch(outgoingRequestsProvider).valueOrNull ?? const [];

    return Row(
      children: [
        Expanded(
          child: switch (status) {
            RelationshipStatus.blocked => OutlinedButton.icon(
                onPressed: () async {
                  await repo.unblockUser(blockerUid: me.uid, blockedUid: otherUid);
                  showToast('Unblocked');
                },
                icon: const Icon(Icons.block_flipped),
                label: const Text('Unblock'),
              ),
            RelationshipStatus.friends => FilledButton.icon(
                onPressed: () async {
                  final chat = await ref.read(chatRepositoryProvider).createOrGetDirectChat(
                        myUid: me.uid,
                        otherUid: otherUid,
                      );
                  if (!context.mounted) return;
                  context.push('/chats/${chat.id}?otherUid=$otherUid');
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message'),
              ),
            RelationshipStatus.incomingRequest => FilledButton.icon(
                onPressed: () async {
                  final req = incoming.firstWhere((r) => r.fromUid == otherUid);
                  await repo.acceptFriendRequest(requestId: req.id, myUid: me.uid);
                  showToast('Request accepted');
                },
                icon: const Icon(Icons.done),
                label: const Text('Accept'),
              ),
            RelationshipStatus.outgoingRequest => OutlinedButton.icon(
                onPressed: () async {
                  await repo.cancelFriendRequest(fromUid: me.uid, toUid: otherUid);
                  showToast('Request cancelled');
                },
                icon: const Icon(Icons.hourglass_top),
                label: const Text('Requested'),
              ),
            RelationshipStatus.none => FilledButton.icon(
                onPressed: () async {
                  await repo.sendFriendRequest(fromUid: me.uid, toUid: otherUid);
                  showToast('Request sent');
                },
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Add friend'),
              ),
          },
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'More',
          onPressed: () async {
            final res = await showModalBottomSheet<String>(
              context: context,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == RelationshipStatus.incomingRequest)
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: const Text('Reject request'),
                        onTap: () => Navigator.of(ctx).pop('reject'),
                      ),
                    if (status == RelationshipStatus.friends)
                      ListTile(
                        leading: const Icon(Icons.person_remove_outlined),
                        title: const Text('Unfriend'),
                        onTap: () => Navigator.of(ctx).pop('unfriend'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Block user'),
                      onTap: () => Navigator.of(ctx).pop('block'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );

            if (res == null) return;

            if (res == 'reject') {
              final req = incoming.firstWhere((r) => r.fromUid == otherUid);
              await repo.rejectFriendRequest(requestId: req.id, myUid: me.uid);
              showToast('Rejected');
            } else if (res == 'unfriend') {
              final ok = await showConfirmActionSheet(
                context,
                title: 'Unfriend?',
                message: 'You will be removed from each other’s friend list.',
                confirmLabel: 'Unfriend',
                icon: Icons.person_remove_outlined,
                destructive: true,
              );
              if (!ok) return;
              await repo.unfriend(myUid: me.uid, otherUid: otherUid);
              showToast('Unfriended');
            } else if (res == 'block') {
              final ok = await showConfirmActionSheet(
                context,
                title: 'Block user?',
                message:
                    'They won’t be able to send you requests or messages. This will also remove friendship if exists.',
                confirmLabel: 'Block',
                icon: Icons.block_outlined,
                destructive: true,
              );
              if (!ok) return;
              await repo.blockUser(blockerUid: me.uid, blockedUid: otherUid);
              showToast('Blocked');
            }
          },
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    );
  }
}

