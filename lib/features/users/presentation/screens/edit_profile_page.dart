import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';
import 'package:syncly/core/widgets/skeletons/profile_skeleton.dart';
import 'package:syncly/core/widgets/avatar_viewer.dart';
import 'package:syncly/features/users/presentation/providers/edit_profile_controller.dart';
import 'package:syncly/features/users/presentation/providers/user_profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  String? _pickedPath;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (x == null) return;
    setState(() => _pickedPath = x.path);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    if (me == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    final asyncMe = ref.watch(userProfileProvider(me.uid));
    final state = ref.watch(editProfileControllerProvider);

    ref.listen(editProfileControllerProvider, (prev, next) {
      final msg = next.error;
      if (msg != null && msg.isNotEmpty) {
        showToast(msg);
        ref.read(editProfileControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/me');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: asyncMe.when(
          loading: () => const ProfileSkeleton(),
          error: (e, _) => Center(child: Text('Failed: $e')),
          data: (u) {
            final user = u;
            if (user != null) {
              _name.text = _name.text.isEmpty ? user.displayName : _name.text;
              _bio.text = _bio.text.isEmpty ? user.bio : _bio.text;
            }

            final avatarWidget = _pickedPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      File(_pickedPath!),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  )
                : GestureDetector(
                    onTap: user == null
                        ? null
                        : () => showAvatarViewer(
                              context,
                              name: user.displayName,
                              photoUrl: user.photoUrl,
                              photoBase64: user.photoBase64,
                            ),
                    child: CustomAvatar(
                      height: 96,
                      width: 96,
                      name: user?.displayName ?? '',
                      image: user?.photoUrl ?? '',
                      base64: user?.photoBase64,
                      network: (user?.photoUrl ?? '').isNotEmpty,
                    ),
                  );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
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
                            Center(child: avatarWidget),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: state.saving ? null : _pickImage,
                              icon: const Icon(Icons.photo_outlined),
                              label: const Text('Change photo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Name is required';
                                if (s.length < 2) return 'Enter a valid name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bio,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.info_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: state.saving
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                if (!(_formKey.currentState?.validate() ?? false)) return;

                                final ok = await ref
                                    .read(editProfileControllerProvider.notifier)
                                    .save(
                                      uid: me.uid,
                                      displayName: _name.text,
                                      bio: _bio.text,
                                      localAvatarPath: _pickedPath,
                                    );
                                if (!context.mounted) return;
                                if (ok) {
                                  showToast('Profile updated');
                                  ref.invalidate(userProfileProvider(me.uid));
                                  context.pop();
                                }
                              },
                        icon: state.saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(state.saving ? 'Saving…' : 'Save changes'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

