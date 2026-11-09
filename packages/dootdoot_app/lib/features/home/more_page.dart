import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proControllerProvider);
    final controller = ref.watch(proControllerProvider.notifier);
    final destinations = controller.destinations;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _tile(
          context,
          icon: Icons.folder_outlined,
          title: 'Projects',
          onTap: () => context.push('/more/projects'),
        ),
        _tile(
          context,
          icon: Icons.layers_outlined,
          title: 'Areas',
          onTap: () => context.push('/more/areas'),
        ),
        _tile(
          context,
          icon: Icons.notes_outlined,
          title: 'Notes',
          onTap: () => context.push('/more/notes'),
        ),
        if (destinations.isNotEmpty) ...[
          const Divider(),
          ...destinations.map(
            (dest) => _tile(
              context,
              icon: dest.icon,
              title: dest.title,
              trailing: isPro ? null : const ProBadge(),
              onTap: () => openProFeature(context, ref, route: dest.route),
            ),
          ),
        ],
        const Divider(),
        _tile(
          context,
          icon: Icons.search,
          title: 'Search',
          onTap: () => context.push('/more/search'),
        ),
        _tile(
          context,
          icon: Icons.switch_account_outlined,
          title: 'Accounts',
          onTap: () => context.push('/more/accounts'),
        ),
        _tile(
          context,
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => context.push('/more/settings'),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
