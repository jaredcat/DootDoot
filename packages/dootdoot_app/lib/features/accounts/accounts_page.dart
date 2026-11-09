import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../../core/widgets/add_account_chooser.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final activeId = ref.watch(activeAccountIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddAccountChooser(context),
        icon: const Icon(Symbols.add),
        label: const Text('Add account'),
      ),
      body: accounts.isEmpty
          ? const Center(child: Text('No accounts yet'))
          : ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final selected = account.id == activeId;
                return ListTile(
                  leading: Icon(
                    selected
                        ? Symbols.check_circle
                        : Symbols.account_circle,
                  ),
                  title: Text(account.label),
                  subtitle: Text('${account.email}\n${account.baseUrl}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final store = ref.read(accountStoreProvider);
                      if (value == 'rename') {
                        final label = await _promptRename(
                          context,
                          account.label,
                        );
                        if (label != null && label.isNotEmpty) {
                          await store.rename(account.id, label);
                          ref.read(accountsProvider.notifier).refresh();
                        }
                      } else if (value == 'remove') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove account?'),
                            content: Text(
                              'Remove ${account.label} from this device? '
                              'Your tududi data on the server is not deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ref
                              .read(offlineCacheProvider)
                              .clearAccount(account.id);
                          await store.removeAccount(account.id);
                          ref.read(accountsProvider.notifier).refresh();
                          final remaining = ref.read(accountsProvider);
                          if (remaining.isEmpty) {
                            if (context.mounted) context.go('/onboarding');
                          } else if (selected) {
                            await ref
                                .read(activeAccountIdProvider.notifier)
                                .switchTo(remaining.first.id);
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                  onTap: () async {
                    await ref
                        .read(activeAccountIdProvider.notifier)
                        .switchTo(account.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to ${account.label}')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Future<String?> _promptRename(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename account'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
