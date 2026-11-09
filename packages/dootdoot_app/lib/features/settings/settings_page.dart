import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    final controller = ref.watch(proControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (account != null) ...[
            ListTile(
              title: const Text('Signed in as'),
              subtitle: Text('${account.email}\n${account.baseUrl}'),
              isThreeLine: true,
            ),
            ListTile(
              leading: const Icon(Icons.switch_account_outlined),
              title: const Text('Manage accounts'),
              onTap: () => context.push('/more/accounts'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('Reminders, Today summary, system settings'),
              onTap: () => context.push('/more/settings/notifications'),
            ),
          ],
          const Divider(),
          ...controller.buildSettingsTiles(context, ref),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About DootDoot'),
            subtitle: const Text(
              'Unofficial tududi companion. Not affiliated with tududi or Chris Veleris.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/jaredcat/dootdoot/blob/main/docs/privacy-policy.md',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('tududi documentation'),
            onTap: () => launchUrl(
              Uri.parse('https://docs.tududi.com/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign out of this account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: account == null
                ? null
                : () async {
                    final store = ref.read(accountStoreProvider);
                    final cache = ref.read(offlineCacheProvider);
                    await cache.clearAccount(account.id);
                    await store.removeAccount(account.id);
                    ref.read(accountsProvider.notifier).refresh();
                    final remaining = ref.read(accountsProvider);
                    if (remaining.isEmpty) {
                      if (context.mounted) context.go('/onboarding');
                    } else {
                      await ref
                          .read(activeAccountIdProvider.notifier)
                          .switchTo(remaining.first.id);
                      if (context.mounted) context.go('/today');
                    }
                  },
          ),
        ],
      ),
    );
  }
}
