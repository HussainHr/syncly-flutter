import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/utils/toast_message.dart';
import 'package:syncly/features/workspaces/presentation/providers/workspace_actions_controller.dart';

class CreateWorkspacePage extends ConsumerStatefulWidget {
  const CreateWorkspacePage({super.key});

  @override
  ConsumerState<CreateWorkspacePage> createState() => _CreateWorkspacePageState();
}

class _CreateWorkspacePageState extends ConsumerState<CreateWorkspacePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final workspace = await ref
        .read(workspaceActionsControllerProvider.notifier)
        .createWorkspace(name: _nameController.text);
    if (!mounted) return;

    if (workspace != null) {
      showToast('Workspace created');
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
      appBar: AppBar(title: const Text('Create workspace')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set up a new workspace for your team.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Workspace name',
                    hintText: 'e.g. Acme Team',
                    prefixIcon: Icon(Icons.workspaces_outlined),
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Workspace name is required';
                    if (trimmed.length < 2) return 'Enter at least 2 characters';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                Text(
                  'A default #general text channel and invite code will be created automatically.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                      : const Text('Create workspace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
