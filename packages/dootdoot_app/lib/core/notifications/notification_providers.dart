import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../features/tasks/task_providers.dart';
import '../providers.dart';
import '../sync/background_sync.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = BackgroundSync.notificationService;
  service.attachPreferences(ref.watch(notificationPreferencesProvider));
  return service;
});

final notificationPreferencesProvider = Provider<NotificationPreferences>((
  ref,
) {
  return NotificationPreferences(ref.watch(sharedPreferencesProvider));
});

final notificationAuthorizationProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.areNotificationsAuthorized();
});

/// Rebuilds local schedules whenever today/upcoming (and Pro habits/goals) change.
final notificationScheduleProvider = FutureProvider<void>((ref) async {
  final account = ref.watch(activeAccountProvider);
  if (account == null) return;

  final service = ref.watch(notificationServiceProvider);
  final isPro = ref.watch(proControllerProvider);

  final today = await ref.watch(tasksProvider(TaskListFilter.today).future);
  final upcoming = await ref.watch(
    tasksProvider(TaskListFilter.upcoming).future,
  );

  final deduped = <String, TududiTask>{};
  for (final task in [...today, ...upcoming]) {
    deduped[task.uid ?? '${task.id}'] = task;
  }

  final habits = isPro
      ? await ref.watch(habitsProvider.future)
      : const <TududiHabit>[];
  final goals = isPro
      ? await ref.watch(goalsProvider.future)
      : const <TududiGoal>[];

  await service.rescheduleFromTasks(
    tasks: deduped.values.toList(),
    habits: habits,
    goals: goals,
    proUnlocked: isPro,
  );
});
