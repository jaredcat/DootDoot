import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../sync/background_sync.dart';
import 'notification_providers.dart';

/// One-time post-login rationale + OS permission prompt, and keeps background
/// sync registered while at least one account is signed in.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap> {
  var _promptScheduled = false;

  Future<void> _maybePrompt() async {
    if (!mounted || _promptScheduled) return;
    final account = ref.read(activeAccountProvider);
    if (account == null) {
      await BackgroundSync.cancel();
      return;
    }

    final prefs = ref.read(notificationPreferencesProvider);
    if (prefs.permissionAsked) {
      await BackgroundSync.register();
      return;
    }

    _promptScheduled = true;
    if (!mounted) return;

    // Register sync in parallel; do not block the permission rationale on it.
    unawaited(BackgroundSync.register());

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Stay on top of due tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'DootDoot can remind you when tasks are due and send a morning '
                  'Today summary. Reminders stay on this device and refresh from '
                  'your Tududi server in the background when the phone can reach it.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _requestAndConfigure(enableDefaults: true);
                  },
                  child: const Text('Enable notifications'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _requestAndConfigure(enableDefaults: false);
                  },
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestAndConfigure({required bool enableDefaults}) async {
    final prefs = ref.read(notificationPreferencesProvider);
    final service = ref.read(notificationServiceProvider);

    await prefs.setPermissionAsked(true);
    ref.invalidate(notificationPreferencesProvider);

    if (enableDefaults) {
      final granted = await service.requestPermission();
      if (granted) {
        await prefs.enableRecommendedDefaults();
        ref.invalidate(notificationPreferencesProvider);
        ref.invalidate(notificationScheduleProvider);
      }
    }

    await BackgroundSync.register();
    ref.invalidate(notificationAuthorizationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    final prefs = ref.watch(notificationPreferencesProvider);

    ref.listen(activeAccountProvider, (previous, next) async {
      if (next == null) {
        await BackgroundSync.cancel();
        await ref.read(notificationServiceProvider).cancelAll();
      } else if (previous == null) {
        await BackgroundSync.register();
        _promptScheduled = false;
      }
    });

    if (account != null) {
      ref.watch(notificationScheduleProvider);
      if (!prefs.permissionAsked && !_promptScheduled) {
        _promptScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Allow a second attempt if the sheet never opens.
          _promptScheduled = false;
          await _maybePrompt();
        });
      }
    }

    return widget.child;
  }
}

/// Routes notification taps into the app.
void handleNotificationPayload(BuildContext context, String? payload) {
  if (payload == null || payload.isEmpty) return;
  if (payload.startsWith('task:')) {
    final uid = payload.substring('task:'.length);
    if (uid.isNotEmpty) context.push('/task/$uid');
    return;
  }
  if (payload == 'digest' || payload == 'habits') {
    context.go('/today');
    return;
  }
  if (payload.startsWith('goal:')) {
    context.go('/more/goals');
  }
}
