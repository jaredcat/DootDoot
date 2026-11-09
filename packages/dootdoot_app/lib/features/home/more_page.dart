import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';

import 'home_shell.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proControllerProvider);
    final controller = ref.watch(proControllerProvider.notifier);
    final destinations = controller.destinations;
    final useCustom = ref.watch(useCustomBottomNavProvider);
    final pins = ref.watch(bottomNavPinsProvider);
    final hiddenRoutes = useCustom
        ? pins
            .map((p) => p.moreRouteToHide)
            .whereType<String>()
            .toSet()
        : <String>{};
    final hiddenKinds = useCustom ? pins.map((p) => p.kind).toSet() : <NavPinKind>{};

    bool hideRoute(String route) => hiddenRoutes.contains(route);
    bool hideKind(NavPinKind kind) => hiddenKinds.contains(kind);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (!hideKind(NavPinKind.projects) && !hideRoute('/more/projects'))
          _tile(
            context,
            icon: Icons.folder_outlined,
            title: 'Projects',
            onTap: () => context.push('/more/projects'),
          ),
        if (!hideKind(NavPinKind.areas) && !hideRoute('/more/areas'))
          _tile(
            context,
            icon: Icons.layers_outlined,
            title: 'Areas',
            onTap: () => context.push('/more/areas'),
          ),
        if (!hideKind(NavPinKind.notes) && !hideRoute('/more/notes'))
          _tile(
            context,
            icon: Icons.notes_outlined,
            title: 'Notes',
            onTap: () => context.push('/more/notes'),
          ),
        if (destinations.isNotEmpty) ...[
          const Divider(),
          ...destinations
              .where((dest) => !hideRoute(dest.route))
              .map(
                (dest) => _tile(
                  context,
                  icon: dest.icon,
                  title: dest.title,
                  subtitle: isPro ? null : 'Pro enhancement',
                  trailing: isPro ? null : const ProBadge(),
                  onTap: () => openProFeature(context, ref, route: dest.route),
                ),
              ),
        ],
        const Divider(),
        if (!hideKind(NavPinKind.search) && !hideRoute('/more/search'))
          _tile(
            context,
            icon: Icons.search,
            title: 'Search',
            onTap: () => context.push('/more/search'),
          ),
        if (!hideKind(NavPinKind.accounts) && !hideRoute('/more/accounts'))
          _tile(
            context,
            icon: Icons.switch_account_outlined,
            title: 'Accounts',
            onTap: () => context.push('/more/accounts'),
          ),
        if (!hideKind(NavPinKind.settings) && !hideRoute('/more/settings'))
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
    String? subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
