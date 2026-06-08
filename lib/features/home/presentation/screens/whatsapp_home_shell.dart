import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/repositories/auth_repository.dart';
import 'package:syncly/core/widgets/logout_confirmation.dart';
import 'package:syncly/core/widgets/exit_confirmation.dart';
import 'package:syncly/features/bottom_bar/presentation/providers/state/bottom_bar_notifier.dart';
import 'package:syncly/features/friends/presentation/screens/friends_page.dart';
import 'package:syncly/features/chats/presentation/screens/chats_page.dart';
import 'package:syncly/features/users/presentation/screens/users_page.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

class WhatsAppHomeShell extends ConsumerWidget {
  const WhatsAppHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bottomBarControllerProvider);
    final notifier = ref.read(bottomBarControllerProvider.notifier);

    Widget tabBody() {
      switch (state.selectedIndex) {
        case 0:
          return const ChatsPage(embedded: true);
        case 1:
          return const UsersPage(embedded: true);
        case 2:
          return const FriendsPage(embedded: true);
        default:
          return const ChatsPage(embedded: true);
      }
    }

    return ExitConfirmationScope(
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final me = ref.watch(currentUserProvider);
              final meProfile = me == null
                  ? null
                  : ref.watch(userProfileProvider(me.uid)).valueOrNull;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Syncly',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  // if (meProfile != null)
                  //   Text(
                  //     meProfile.displayName,
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  //           color: Theme.of(context)
                  //               .colorScheme
                  //               .onSurfaceVariant,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //   ),
                ],
              );
            },
          ),
          actions: [
            Builder(
              builder: (context) {
                final me = ref.watch(currentUserProvider);
                final meProfile = me == null
                    ? null
                    : ref.watch(userProfileProvider(me.uid)).valueOrNull;

                return GestureDetector(
                  onTap: () => context.push('/me'),
                  onLongPress: meProfile == null
                      ? null
                      : () => showAvatarViewer(
                            context,
                            name: meProfile.displayName,
                            photoUrl: meProfile.photoUrl,
                            photoBase64: meProfile.photoBase64,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomAvatar(
                      height: 34,
                      width: 34,
                      name: meProfile?.displayName ?? (me?.email ?? 'Me'),
                      image: meProfile?.photoUrl ?? '',
                      base64: meProfile?.photoBase64,
                      network: (meProfile?.photoUrl ?? '').isNotEmpty,
                    ),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: (value) async {
                if (value == 'settings') {
                  context.push('/settings');
                } else if (value == 'logout') {
                  final ok = await showLogoutConfirmationSheet(context);
                  if (ok) {
                    await ref.read(authRepositoryProvider).signOut();
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: tabBody(),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  _NavItem(
                    label: 'Chats',
                    icon: Icons.chat_bubble_outline,
                    selected: state.selectedIndex == 0,
                    onTap: () => notifier.onItemTapped(0),
                  ),
                  _NavItem(
                    label: 'Users',
                    icon: Icons.people_outline,
                    selected: state.selectedIndex == 1,
                    onTap: () => notifier.onItemTapped(1),
                  ),
                  _NavItem(
                    label: 'Friends',
                    icon: Icons.person_add_alt_1_outlined,
                    selected: state.selectedIndex == 2,
                    onTap: () => notifier.onItemTapped(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary.withValues(alpha: 0.22) : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

