import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_bootstrap.dart';
import 'core/notifications/notification_providers.dart';
import 'core/offline/connectivity_sync.dart';
import 'core/offline/offline_write_coordinator.dart';
import 'core/routing/app_router.dart';

class DootdootApp extends ConsumerStatefulWidget {
  const DootdootApp({super.key});

  @override
  ConsumerState<DootdootApp> createState() => _DootdootAppState();
}

class _DootdootAppState extends ConsumerState<DootdootApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(notificationServiceProvider);
      service.initialize(
        onTap: (payload) {
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            handleNotificationPayload(context, payload);
          }
        },
      );
      // Start connectivity → outbox drain listener (Pro).
      ref.read(connectivitySyncProvider);
      ref.read(syncStatusProvider.notifier).refreshPending();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(offlineWriteCoordinatorProvider).drain();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DootDoot',
      debugShowCheckedModeBanner: false,
      theme: DootTheme.light(),
      darkTheme: DootTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
