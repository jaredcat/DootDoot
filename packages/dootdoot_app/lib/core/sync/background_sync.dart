import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:workmanager/workmanager.dart';

import '../accounts/account_secrets.dart';
import '../accounts/account_store.dart';
import '../notifications/notification_preferences.dart';
import '../notifications/notification_service.dart';

/// Periodic on-device Tududi refresh + local notification reschedule.
///
/// Talks only to each account's configured Tududi server using the stored
/// API token. No DootDoot push/relay server is involved.
abstract final class BackgroundSync {
  static const uniqueName = 'com.codekitties.dootdoot.sync';
  static const taskName = 'dootdootPeriodicSync';
  static const frequency = Duration(minutes: 15);

  static final NotificationService notificationService = NotificationService();

  static bool get _skipNativeWorkmanager =>
      kIsWeb || Platform.environment.containsKey('FLUTTER_TEST');

  static Future<void> initializeWorker() async {
    if (_skipNativeWorkmanager) return;
    try {
      await Workmanager().initialize(dootdootCallbackDispatcher);
    } catch (_) {
      // Missing plugin.
    }
  }

  static Future<void> register() async {
    if (_skipNativeWorkmanager) return;
    try {
      await Workmanager().registerPeriodicTask(
        uniqueName,
        taskName,
        frequency: frequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {
      // Missing plugin.
    }
  }

  static Future<void> cancel() async {
    if (_skipNativeWorkmanager) return;
    try {
      await Workmanager().cancelByUniqueName(uniqueName);
    } catch (_) {
      // Missing plugin.
    }
  }

  /// Fetches tasks (and Pro habits/goals when unlocked) then rebuilds schedules.
  static Future<void> run({NotificationService? notifications}) async {
    final service = notifications ?? notificationService;
    try {
      final prefs = await SharedPreferences.getInstance();
      final store = AccountStore(prefs);
      final accounts = store.loadAccounts();
      if (accounts.isEmpty) {
        await cancel();
        return;
      }

      final notifPrefs = NotificationPreferences(prefs);
      service.attachPreferences(notifPrefs);
      await service.initialize();

      final factory = const TududiClientFactory();
      final secrets = AccountSecrets();
      final proUnlocked = prefs.getBool('dootdoot.proUnlocked') ?? false;

      final allTasks = <TududiTask>[];
      final allHabits = <TududiHabit>[];
      final allGoals = <TududiGoal>[];

      for (final account in accounts) {
        final token = await secrets.readBearerToken(account.id);
        if (token == null || token.isEmpty) continue;
        final client = factory.create(
          TududiClientConfig(baseUrl: account.baseUrl, bearerToken: token),
        );
        try {
          final today = await client.listTasks(type: 'today');
          final upcoming = await client.listTasks(type: 'upcoming');
          allTasks.addAll([...today, ...upcoming]);

          if (proUnlocked) {
            try {
              allHabits.addAll(await client.listHabits());
            } catch (_) {}
            try {
              allGoals.addAll(await client.listGoals());
            } catch (_) {}
          }
        } catch (_) {
          // Best-effort: reachability / auth failures retry on the next wake.
        }
      }

      final deduped = <String, TududiTask>{};
      for (final task in allTasks) {
        final key = task.uid ?? '${task.id}';
        deduped[key] = task;
      }

      await service.rescheduleFromTasks(
        tasks: deduped.values.toList(),
        habits: allHabits,
        goals: allGoals,
        proUnlocked: proUnlocked,
      );
    } catch (_) {
      // Never crash the worker for routine failures.
    }
  }
}

@pragma('vm:entry-point')
void dootdootCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await BackgroundSync.run();
    return true;
  });
}
