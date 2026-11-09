import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';

import '../../features/accounts/accounts_page.dart';
import '../../features/areas/area_detail_page.dart';
import '../../features/areas/areas_page.dart';
import '../../features/auth/sign_in_page.dart';
import '../../features/home/home_shell.dart';
import '../../features/notes/note_editor_page.dart';
import '../../features/notes/notes_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/projects/project_detail_page.dart';
import '../../features/projects/projects_page.dart';
import '../../features/search/search_page.dart';
import '../../features/settings/notifications_settings_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/tasks/task_detail_page.dart';
import '../notifications/notification_bootstrap.dart';
import '../providers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

String _navRedirect(List<NavPin> pins, NavPinKind kind) {
  for (var i = 0; i < pins.length; i++) {
    if (pins[i].kind == kind) return '/nav/$i';
  }
  if (pins.isNotEmpty) return '/nav/0';
  return '/more';
}

List<NavPin> _livePins(BuildContext context) {
  return ProviderScope.containerOf(context).read(bottomNavPinsProvider);
}

List<RouteBase> _moreChildRoutes(List<ProMoreRoute> proRoutes) => [
      GoRoute(
        path: 'projects',
        builder: (context, state) => const ProjectsPage(),
      ),
      GoRoute(
        path: 'projects/:uid',
        builder: (context, state) =>
            ProjectDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: 'areas',
        builder: (context, state) => const AreasPage(),
      ),
      GoRoute(
        path: 'areas/:uid',
        builder: (context, state) =>
            AreaDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: 'notes',
        builder: (context, state) => const NotesPage(),
      ),
      GoRoute(
        path: 'notes/:uid',
        builder: (context, state) =>
            NoteEditorPage(uid: state.pathParameters['uid']),
      ),
      GoRoute(
        path: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: 'settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) =>
                const NotificationsSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: 'accounts',
        builder: (context, state) => const AccountsPage(),
      ),
      ...proRoutes.map(
        (route) => GoRoute(path: route.path, builder: route.builder),
      ),
    ];

StatefulShellBranch _moreBranch(List<ProMoreRoute> proRoutes) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/more',
        builder: (context, state) => const MoreTab(),
        routes: _moreChildRoutes(proRoutes),
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final accounts = ref.watch(accountsProvider);
  // Only the unlock bool — pin edits must not recreate the router (that would
  // reset the stack and kick the user out of Settings → Navigation).
  final isPro = ref.watch(proControllerProvider);
  final controller = ref.read(proControllerProvider.notifier);
  final proRoutes = controller.buildMoreRoutes();
  final useCustom = controller.supportsCustomNav && isPro;

  // Custom mode keeps a stable 5 slot branches + More so pin edits update the
  // bar without recreating GoRouter. Only unlock/lock rebuilds the tree.
  final initialLocation = accounts.isEmpty
      ? '/onboarding'
      : useCustom
          ? '/nav/0'
          : '/today';

  final List<StatefulShellBranch> branches;
  if (useCustom) {
    branches = [
      for (var i = 0; i < kCustomNavSlotCount; i++)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nav/$i',
              builder: (context, state) => NavPinTab(slotIndex: i),
            ),
          ],
        ),
      _moreBranch(proRoutes),
    ];
  } else {
    branches = [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayTab(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/upcoming',
            builder: (context, state) => const UpcomingTab(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxTab(),
          ),
        ],
      ),
      _moreBranch(proRoutes),
    ];
  }

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          final kind = state.uri.queryParameters['kind'] ?? 'cloud';
          final add = state.uri.queryParameters['add'] == '1';
          return SignInPage(kind: kind, addingAccount: add);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NotificationBootstrap(
            child: HomeShell(navigationShell: navigationShell),
          );
        },
        branches: branches,
      ),
      GoRoute(
        path: '/task/:uid',
        builder: (context, state) =>
            TaskDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/notes/new',
        builder: (context, state) => const NoteEditorPage(uid: null),
      ),
      if (useCustom) ...[
        GoRoute(
          path: '/today',
          redirect: (context, state) =>
              _navRedirect(_livePins(context), NavPinKind.today),
        ),
        GoRoute(
          path: '/upcoming',
          redirect: (context, state) =>
              _navRedirect(_livePins(context), NavPinKind.upcoming),
        ),
        GoRoute(
          path: '/inbox',
          redirect: (context, state) =>
              _navRedirect(_livePins(context), NavPinKind.inbox),
        ),
      ],
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(state.error?.toString() ?? 'Not found')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
