import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/repositories/auth_repository.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/core/widgets/logout_confirmation.dart';
import 'package:syncly/features/settings/presentation/providers/settings_controller.dart';
import 'package:syncly/features/users/domain/entities/app_user.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';
import 'package:syncly/features/users/presentation/providers/users_providers.dart';

class SettingsPage extends ConsumerWidget {
  final bool embedded;

  const SettingsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final me = ref.watch(currentUserProvider);
    final myProfileAsync =
        me == null ? const AsyncValue<AppUser?>.data(null) : ref.watch(userProfileProvider(me.uid));

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Appearance',
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Theme'),
              subtitle: Text(_themeLabel(settings.themeMode)),
              onTap: () async {
                final res = await showModalBottomSheet<ThemeMode>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          groupValue: settings.themeMode,
                          onChanged: (v) => Navigator.of(ctx).pop(v),
                          title: const Text('System'),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          groupValue: settings.themeMode,
                          onChanged: (v) => Navigator.of(ctx).pop(v),
                          title: const Text('Light'),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          groupValue: settings.themeMode,
                          onChanged: (v) => Navigator.of(ctx).pop(v),
                          title: const Text('Dark'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
                if (res != null) await controller.setThemeMode(res);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Notifications',
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_none_outlined),
              value: settings.notificationsEnabled,
              onChanged: (v) async {
                await controller.setNotificationsEnabled(v);
                showToast(v ? 'Notifications enabled' : 'Notifications disabled');
              },
              title: const Text('Push notifications'),
              subtitle: const Text('New messages, friend requests, calls'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Privacy',
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.email_outlined),
              value: settings.showMyEmail,
              onChanged: (v) async {
                await controller.setShowMyEmail(v);
                showToast(v ? 'Email will be shown on your profile' : 'Email hidden');
              },
              title: const Text('Show my email on my profile'),
              subtitle: const Text('Other users will never see it'),
            ),
            const Divider(height: 1),
            myProfileAsync.when(
              loading: () => const ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Loading privacy…'),
              ),
              error: (e, _) => ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy controls'),
                subtitle: Text('Failed to load: $e'),
              ),
              data: (u) {
                if (me == null || u == null) {
                  return const ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy controls'),
                    subtitle: Text('Sign in to manage privacy'),
                  );
                }

                Future<void> setAudience(String field, PrivacyAudience audience) async {
                  await ref.watch(usersRepositoryProvider).updateMyPrivacy(
                        uid: me.uid,
                        privacyLastSeen: field == 'lastSeen' ? audience.toFirestore() : null,
                        privacyOnline: field == 'online' ? audience.toFirestore() : null,
                        privacyPhoto: field == 'photo' ? audience.toFirestore() : null,
                        privacyAbout: field == 'about' ? audience.toFirestore() : null,
                      );
                  ref.invalidate(userProfileProvider(me.uid));
                }

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Last seen'),
                      subtitle: Text(_audienceLabel(u.privacyLastSeen)),
                      onTap: () async {
                        final res = await _pickAudienceSheet(
                          context,
                          title: 'Last seen',
                          current: u.privacyLastSeen,
                        );
                        if (res != null) {
                          await setAudience('lastSeen', res);
                          showToast('Last seen updated');
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.circle_outlined),
                      title: const Text('Online status'),
                      subtitle: Text(_audienceLabel(u.privacyOnline)),
                      onTap: () async {
                        final res = await _pickAudienceSheet(
                          context,
                          title: 'Online status',
                          current: u.privacyOnline,
                        );
                        if (res != null) {
                          await setAudience('online', res);
                          showToast('Online status updated');
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: const Text('Profile photo'),
                      subtitle: Text(_audienceLabel(u.privacyPhoto)),
                      onTap: () async {
                        final res = await _pickAudienceSheet(
                          context,
                          title: 'Profile photo',
                          current: u.privacyPhoto,
                        );
                        if (res != null) {
                          await setAudience('photo', res);
                          showToast('Profile photo privacy updated');
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: Text(_audienceLabel(u.privacyAbout)),
                      onTap: () async {
                        final res = await _pickAudienceSheet(
                          context,
                          title: 'About',
                          current: u.privacyAbout,
                        );
                        if (res != null) {
                          await setAudience('about', res);
                          showToast('About privacy updated');
                        }
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.done_all_outlined),
                      value: u.readReceiptsEnabled,
                      onChanged: (v) async {
                        await ref.watch(usersRepositoryProvider).updateMyPrivacy(
                              uid: me.uid,
                              readReceiptsEnabled: v,
                            );
                        ref.invalidate(userProfileProvider(me.uid));
                        showToast(v ? 'Read receipts enabled' : 'Read receipts disabled');
                      },
                      title: const Text('Read receipts'),
                      subtitle: const Text('Show when you read messages'),
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.edit_outlined),
                      value: u.typingIndicatorEnabled,
                      onChanged: (v) async {
                        await ref.watch(usersRepositoryProvider).updateMyPrivacy(
                              uid: me.uid,
                              typingIndicatorEnabled: v,
                            );
                        ref.invalidate(userProfileProvider(me.uid));
                        showToast(v ? 'Typing indicator enabled' : 'Typing indicator disabled');
                      },
                      title: const Text('Typing indicator'),
                      subtitle: const Text('Show when you are typing'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Language',
          children: [
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: Text(settings.languageCode.toUpperCase()),
              onTap: () async {
                final res = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('English'),
                          onTap: () => Navigator.of(ctx).pop('en'),
                        ),
                        ListTile(
                          title: const Text('Bangla'),
                          onTap: () => Navigator.of(ctx).pop('bn'),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            'Language switching UI is ready. Full app localization will be added when we add ARB files.',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (res != null) await controller.setLanguageCode(res);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Account',
          children: [
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Logout',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final ok = await showLogoutConfirmationSheet(context);
                if (ok) {
                  await ref.read(authRepositoryProvider).signOut();
                }
              },
            ),
          ],
        ),
      ],
    );

    if (embedded) return SafeArea(child: content);
    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: SafeArea(child: content));
  }
}

String _themeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

String _audienceLabel(PrivacyAudience a) {
  return switch (a) {
    PrivacyAudience.everyone => 'Everyone',
    PrivacyAudience.friends => 'My friends',
    PrivacyAudience.nobody => 'Nobody',
  };
}

Future<PrivacyAudience?> _pickAudienceSheet(
  BuildContext context, {
  required String title,
  required PrivacyAudience current,
}) {
  return showModalBottomSheet<PrivacyAudience>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          RadioListTile<PrivacyAudience>(
            value: PrivacyAudience.everyone,
            groupValue: current,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            title: const Text('Everyone'),
          ),
          RadioListTile<PrivacyAudience>(
            value: PrivacyAudience.friends,
            groupValue: current,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            title: const Text('My friends'),
          ),
          RadioListTile<PrivacyAudience>(
            value: PrivacyAudience.nobody,
            groupValue: current,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            title: const Text('Nobody'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

