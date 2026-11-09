import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/providers.dart';

enum TaskListFilter { today, upcoming, inbox, someday, all }

final tasksProvider = FutureProvider.family<List<TududiTask>, TaskListFilter>((
  ref,
  filter,
) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];

  final account = ref.watch(activeAccountProvider);
  final isPro = ref.watch(proControllerProvider);
  final offlineEnabled =
      isPro && ref.read(proControllerProvider.notifier).offlineEnabled;
  final cache = ref.watch(offlineCacheProvider);

  try {
    final type = switch (filter) {
      TaskListFilter.today => 'today',
      TaskListFilter.upcoming => 'upcoming',
      TaskListFilter.inbox => 'inbox',
      TaskListFilter.someday => 'someday',
      TaskListFilter.all => null,
    };
    final tasks = await client.listTasks(type: type);
    if (account != null && offlineEnabled) {
      await cache.putJson(
        account.id,
        'tasks_${filter.name}',
        tasks
            .map(
              (t) => {
                'id': t.id,
                'uid': t.uid,
                'name': t.displayName,
                'status': t.status,
                'due_date': t.dueDate,
                'priority': t.priority,
                'project_name': t.projectName,
              },
            )
            .toList(),
      );
    }
    return tasks;
  } catch (e) {
    if (account != null && offlineEnabled) {
      final cached = cache.getJson(account.id, 'tasks_${filter.name}');
      if (cached is List) {
        return cached
            .whereType<Map>()
            .map((e) => TududiTask.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    rethrow;
  }
});

final taskDetailProvider = FutureProvider.family<TududiTask, String>((
  ref,
  uid,
) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) {
    throw TududiApiException(message: 'Not signed in');
  }
  return client.getTask(uid);
});

final projectsProvider = FutureProvider<List<TududiProject>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  return client.listProjects();
});

final areasProvider = FutureProvider<List<TududiArea>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  return client.listAreas();
});

final notesProvider = FutureProvider<List<TududiNote>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  return client.listNotes();
});

final goalsProvider = FutureProvider<List<TududiGoal>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  return client.listGoals();
});

final habitsProvider = FutureProvider<List<TududiHabit>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  return client.listHabits();
});
