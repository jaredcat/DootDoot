import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Extra More-tab destination contributed by a Pro build.
class ProNavDestination {
  const ProNavDestination({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;

  /// Full location, e.g. `/more/calendar`.
  final String route;
}

/// Shared Pro More destinations. Free lists these as locked; store wires routes.
abstract final class ProDestinations {
  static const all = <ProNavDestination>[
    ProNavDestination(
      icon: Icons.calendar_month_outlined,
      title: 'Calendar',
      route: '/more/calendar',
    ),
    ProNavDestination(
      icon: Icons.flag_outlined,
      title: 'Goals',
      route: '/more/goals',
    ),
    ProNavDestination(
      icon: Icons.loop,
      title: 'Habits',
      route: '/more/habits',
    ),
    ProNavDestination(
      icon: Icons.view_kanban_outlined,
      title: 'Boards',
      route: '/more/boards',
    ),
  ];
}

/// Child route under `/more` contributed by a Pro build.
class ProMoreRoute {
  const ProMoreRoute({
    required this.path,
    required this.builder,
  });

  /// Relative path, e.g. `calendar`.
  final String path;
  final Widget Function(BuildContext context, GoRouterState state) builder;
}
