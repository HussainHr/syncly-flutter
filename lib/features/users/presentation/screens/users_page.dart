import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/utils/privacy.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/widgets/empty_state.dart';
import 'package:syncly/core/widgets/skeletons/list_tile_skeleton.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/features/friends/presentation/providers/relationship_provider.dart';
import 'package:syncly/features/users/presentation/providers/users_list_controller.dart';

class UsersPage extends ConsumerStatefulWidget {
  final bool embedded;

  const UsersPage({super.key, this.embedded = false});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListControllerProvider);
    final me = ref.watch(currentUserProvider);

    final body = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) =>
                    ref.read(usersListControllerProvider.notifier).refresh(query: v),
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                            ref
                                .read(usersListControllerProvider.notifier)
                                .refresh(query: '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
                    ref.read(usersListControllerProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(usersListControllerProvider.notifier)
                      .refresh(query: _search.text),
                  child: state.loading
                      ? const ListSkeleton(itemCount: 10)
                      : state.users.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                EmptyState(
                                  icon: Icons.people_outline,
                                  title: 'No users found',
                                  message: 'Try a different name or clear the search.',
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: state.users.length + (state.loadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                if (i >= state.users.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }

                                final u = state.users[i];
                                final rel = ref.watch(relationshipProvider(u.uid));
                                final isMe = me?.uid == u.uid;
                                final canSeePhoto = canSeeByAudience(
                                  audience: u.privacyPhoto,
                                  isMe: isMe,
                                  relationship: rel,
                                );
                                final canSeeAbout = canSeeByAudience(
                                  audience: u.privacyAbout,
                                  isMe: isMe,
                                  relationship: rel,
                                );
                                final canSeeOnline = canSeeByAudience(
                                  audience: u.privacyOnline,
                                  isMe: isMe,
                                  relationship: rel,
                                );
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  onTap: () => context.push('/users/${u.uid}'),
                                  leading: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: () => showAvatarViewer(
                                          context,
                                          name: u.displayName,
                                          photoUrl: canSeePhoto ? u.photoUrl : null,
                                          photoBase64: canSeePhoto ? u.photoBase64 : null,
                                        ),
                                        child: CustomAvatar(
                                          height: 46,
                                          width: 46,
                                          name: u.displayName,
                                          image: canSeePhoto ? (u.photoUrl ?? '') : '',
                                          base64: canSeePhoto ? u.photoBase64 : null,
                                          network: canSeePhoto && (u.photoUrl ?? '').isNotEmpty,
                                        ),
                                      ),
                                      if (canSeeOnline)
                                        Positioned(
                                          right: -1,
                                          bottom: -1,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: u.isOnline
                                                  ? Colors.green
                                                  : Colors.grey.withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context).scaffoldBackgroundColor,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    u.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    canSeeAbout && u.bio.isNotEmpty
                                        ? u.bio
                                        : 'Tap to view profile',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        );

    if (widget.embedded) {
      return SafeArea(child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            onPressed: () => context.push('/me'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

