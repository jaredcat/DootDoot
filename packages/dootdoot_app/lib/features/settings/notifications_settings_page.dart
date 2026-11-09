import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/sync/background_sync.dart';

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final authorized = ref.watch(notificationAuthorizationProvider);
    final isPro = ref.watch(proControllerProvider);
    final service = ref.watch(notificationServiceProvider);

    final statusLabel = authorized.when(
      data: (ok) {
        if (!prefs.permissionAsked) return 'Not asked yet';
        return ok ? 'Allowed' : 'Denied in system settings';
      },
      loading: () => 'Checking…',
      error: (_, _) => 'Unknown',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Permission'),
            subtitle: Text(statusLabel),
            trailing: TextButton(
              onPressed: () async {
                await service.openSystemNotificationSettings();
                ref.invalidate(notificationAuthorizationProvider);
              },
              child: const Text('System settings'),
            ),
          ),
          if (prefs.permissionAsked &&
              !(authorized.asData?.value ?? false)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Notifications are off for DootDoot. Turn them on in system '
                'settings, then return here.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Divider(),
          SwitchListTile(
            title: const Text('Task due reminders'),
            subtitle: const Text(
              'Alert when a task reaches its due date or time',
            ),
            value: prefs.taskDueEnabled,
            onChanged: (value) async {
              await prefs.setTaskDueEnabled(value);
              ref.invalidate(notificationPreferencesProvider);
              ref.invalidate(notificationScheduleProvider);
            },
          ),
          SwitchListTile(
            title: const Text('Today summary'),
            subtitle: Text(
              'Morning overview around ${prefs.digestHour.toString().padLeft(2, '0')}:00',
            ),
            value: prefs.dailyDigestEnabled,
            onChanged: (value) async {
              await prefs.setDailyDigestEnabled(value);
              ref.invalidate(notificationPreferencesProvider);
              ref.invalidate(notificationScheduleProvider);
            },
          ),
          ListTile(
            enabled: prefs.dailyDigestEnabled,
            title: const Text('Summary time'),
            subtitle: Text(
              TimeOfDay(hour: prefs.digestHour, minute: 0).format(context),
            ),
            onTap: !prefs.dailyDigestEnabled
                ? null
                : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: prefs.digestHour, minute: 0),
                    );
                    if (picked == null) return;
                    await prefs.setDigestHour(picked.hour);
                    ref.invalidate(notificationPreferencesProvider);
                    ref.invalidate(notificationScheduleProvider);
                  },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Habit reminders'),
            subtitle: Text(
              isPro
                  ? 'Evening nudge for habits not done today'
                  : 'Pro enhancement',
            ),
            secondary: isPro ? null : const ProBadge(),
            value: isPro && prefs.habitsEnabled,
            onChanged: !isPro
                ? null
                : (value) async {
                    await prefs.setHabitsEnabled(value);
                    ref.invalidate(notificationPreferencesProvider);
                    ref.invalidate(notificationScheduleProvider);
                  },
          ),
          SwitchListTile(
            title: const Text('Goal deadlines'),
            subtitle: Text(
              isPro ? 'Alert on a goal’s target date' : 'Pro enhancement',
            ),
            secondary: isPro ? null : const ProBadge(),
            value: isPro && prefs.goalsEnabled,
            onChanged: !isPro
                ? null
                : (value) async {
                    await prefs.setGoalsEnabled(value);
                    ref.invalidate(notificationPreferencesProvider);
                    ref.invalidate(notificationScheduleProvider);
                  },
          ),
          const Divider(),
          ListTile(
            title: const Text('Background refresh'),
            subtitle: const Text(
              'DootDoot periodically refreshes your Tududi data on this device '
              'so reminders stay current. Timing is controlled by the OS and '
              'needs network access to your Tududi server.',
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync now'),
            onTap: () async {
              await BackgroundSync.run(
                notifications: ref.read(notificationServiceProvider),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refresh finished')),
                );
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              kIsWeb
                  ? 'Notification categories are managed in the browser.'
                  : Platform.isAndroid
                  ? 'On Android, these types also appear under system '
                        'App info → Notifications → Categories.'
                  : 'On iOS, system Settings controls notifications for the '
                        'whole app. Choose which kinds of alerts you want here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
