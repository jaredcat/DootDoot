import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers.dart';
import 'add_account_chooser.dart';

Future<void> showAccountSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const AccountSwitcherSheet(),
  );
}

class AccountSwitcherSheet extends ConsumerWidget {
  const AccountSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final activeId = ref.watch(activeAccountIdProvider);
    ref.watch(proControllerProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: TextButton(
              onPressed: () {
                // go() switches the shell to the More branch. push() stacks
                // /more/accounts onto the current tab and leaves the shell FAB up.
                Navigator.pop(context);
                context.go('/more/accounts');
              },
              child: const Text('Manage'),
            ),
          ),
          ...accounts.map((account) {
            final selected = account.id == activeId;
            return ListTile(
              leading: Icon(
                selected ? Symbols.check_circle : Symbols.circle,
              ),
              title: Text(account.label),
              subtitle: Text('${account.email}\n${account.hostLabel}'),
              isThreeLine: true,
              onTap: () async {
                await ref
                    .read(activeAccountIdProvider.notifier)
                    .switchTo(account.id);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }),
          ListTile(
            leading: const Icon(Symbols.add),
            title: const Text('Add account'),
            trailing: canAddAccount(
                  accountCount: accounts.length,
                  controller: ref.read(proControllerProvider.notifier),
                )
                ? null
                : const ProBadge(),
            onTap: () async {
              Navigator.pop(context);
              await showAddAccountChooser(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
