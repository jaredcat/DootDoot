import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers.dart';

/// Picks Tududi Cloud vs self-hosted before opening the sign-in form.
///
/// Always opens, even at the free account cap — the Add Account page then
/// explains that multiple accounts need Pro.
Future<void> showAddAccountChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => const _AddAccountChooserSheet(),
  );
}

class _AddAccountChooserSheet extends ConsumerWidget {
  const _AddAccountChooserSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    ref.watch(proControllerProvider);
    final locked = !canAddAccount(
      accountCount: accounts.length,
      controller: ref.read(proControllerProvider.notifier),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Add account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              locked
                  ? 'Multiple accounts are a DootDoot Pro enhancement'
                  : 'Choose where this account lives',
            ),
            trailing: locked ? const ProBadge() : null,
          ),
          ListTile(
            leading: const Icon(Symbols.cloud),
            title: const Text('tududi Cloud'),
            subtitle: const Text('app.tududi.com'),
            trailing: locked ? const ProBadge() : null,
            onTap: () {
              Navigator.pop(context);
              context.push('/sign-in?kind=cloud&add=1');
            },
          ),
          ListTile(
            leading: const Icon(Symbols.dns),
            title: const Text('Self-hosted server'),
            subtitle: const Text('Your own tududi URL'),
            trailing: locked ? const ProBadge() : null,
            onTap: () {
              Navigator.pop(context);
              context.push('/sign-in?kind=self&add=1');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
