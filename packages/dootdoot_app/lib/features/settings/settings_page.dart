import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../../core/widgets/shell_app_bar_actions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    final controller = ref.watch(proControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [ShellAppBarActions()],
      ),
      body: ListView(
        children: [
          if (account != null) ...[
            ListTile(
              title: const Text('Signed in as'),
              subtitle: Text('${account.email}\n${account.baseUrl}'),
              isThreeLine: true,
            ),
            ListTile(
              leading: const Icon(Symbols.switch_account),
              title: const Text('Manage accounts'),
              onTap: () => context.push('/more/accounts'),
            ),
            ListTile(
              leading: const Icon(Symbols.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('Reminders, Today summary, system settings'),
              onTap: () => context.push('/more/settings/notifications'),
            ),
            ListTile(
              leading: const Icon(Symbols.wb_sunny),
              title: const Text('Today'),
              subtitle: const Text('Show or hide Overdue, Suggested, Completed'),
              onTap: () => context.push('/more/settings/today'),
            ),
          ],
          const Divider(),
          ...controller.buildSettingsTiles(context, ref),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.info),
            title: const Text('About DootDoot'),
            subtitle: const Text(
              'Unofficial tududi companion. Not affiliated with tududi or Chris Veleris.',
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.privacy_tip),
            title: const Text('Privacy policy'),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/jaredcat/dootdoot/blob/main/docs/privacy-policy.md',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.open_in_new),
            title: const Text('tududi documentation'),
            onTap: () => launchUrl(
              Uri.parse('https://docs.tududi.com/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Symbols.logout,
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
