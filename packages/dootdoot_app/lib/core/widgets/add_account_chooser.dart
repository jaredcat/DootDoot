import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Picks Tududi Cloud vs self-hosted before opening the sign-in form.
Future<void> showAddAccountChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Add account',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            subtitle: const Text('Choose where this account lives'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Tududi Cloud'),
            subtitle: const Text('app.tududi.com'),
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/sign-in?kind=cloud&add=1');
            },
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Self-hosted server'),
            subtitle: const Text('Your own Tududi URL'),
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/sign-in?kind=self&add=1');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
