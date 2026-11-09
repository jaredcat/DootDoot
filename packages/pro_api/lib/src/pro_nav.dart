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
