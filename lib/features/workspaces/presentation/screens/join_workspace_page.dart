import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspace_actions_controller.dart';

class JoinWorkspacePage extends ConsumerStatefulWidget {
  const JoinWorkspacePage({super.key});

  @override
  ConsumerState<JoinWorkspacePage> createState() => _JoinWorkspacePageState();
}

class _JoinWorkspacePageState extends ConsumerState<JoinWorkspacePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final workspace = await ref
        .read(workspaceActionsControllerProvider.notifier)
        .joinWorkspace(inviteCode: _codeController.text);
    if (!mounted) return;

    if (workspace != null) {
      showToast('Joined ${workspace.name}');
      context.go('/workspaces/${workspace.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceActionsControllerProvider);

    ref.listen(workspaceActionsControllerProvider, (prev, next) {
      final msg = next.error;
      if (msg != null && msg.isNotEmpty) {
        showToast(msg);
        ref.read(workspaceActionsControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Join workspace')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the invite code shared by your workspace host.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Invite code',
                    hintText: 'AB12CD34',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Invite code is required';
                    if (trimmed.length < 6) return 'Enter a valid invite code';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join workspace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
