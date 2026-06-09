import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/repositories/auth_repository.dart';
import 'package:syncly/core/widgets/logout_confirmation.dart';
import 'package:syncly/core/widgets/exit_confirmation.dart';
import 'package:syncly/features/workspaces/presentation/screens/workspaces_page.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

class WhatsAppHomeShell extends ConsumerWidget {
  const WhatsAppHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExitConfirmationScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syncly',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'Workspaces',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
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
        body: const WorkspacesPage(),
      ),
    );
  }
}
