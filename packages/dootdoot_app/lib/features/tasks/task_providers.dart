import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/offline/offline_write_coordinator.dart';
import '../../core/providers.dart';
import 'task_list_organize.dart';

enum TaskListFilter { today, upcoming, inbox, someday, all }

Map<String, dynamic> _taskListCacheJson(TududiTask t) => {
  'id': t.id,
  'uid': t.uid,
  'name': t.displayName,
  'status': t.status,
  'due_date': t.dueDate,
  if (t.dueTime != null) 'due_time': t.dueTime,
  if (t.deferUntil != null) 'defer_until': t.deferUntil,
  if (t.parentTaskId != null) 'parent_task_id': t.parentTaskId,
  'priority': t.priority,
  if (t.projectId != null) 'project_id': t.projectId,
  if (t.projectUid != null) 'project_uid': t.projectUid,
  'project_name': t.projectName,
  if (t.note != null) 'note': t.note,
  if (t.completedAt != null) 'completed_at': t.completedAt,
  if (t.recurrenceType != null) 'recurrence_type': t.recurrenceType,
  if (t.tags.isNotEmpty) 'tags': t.tags.map((tag) => tag.toJson()).toList(),
  if (t.subtasks.isNotEmpty)
    'subtasks': t.subtasks.map(_taskListCacheJson).toList(),
};

/// Assembles Today like Tududi metrics queries (not server `type=today` alone).
Future<List<TududiTask>> fetchTodayTasks(TududiClient client) async {
  final results = await Future.wait([
    client.listTasks(type: 'all', status: 'active'),
    client.listTasks(type: 'all', status: 'completed'),
  ]);
  final active = excludeSubtasks(results[0]);
  final completed = excludeSubtasks(results[1]);
  final core = filterTodayCandidates([...active, ...completed]);
  final coreKeys = {for (final t in core) t.uid ?? '${t.id}'};
  final suggested = rankSuggestedCandidates(
    active.where((t) => !coreKeys.contains(t.uid ?? '${t.id}')),
  );
  final deduped = <String, TududiTask>{};
  for (final task in [...core, ...suggested]) {
    deduped[task.uid ?? '${task.id}'] = task;
  }
  return deduped.values.toList();
}

bool _offlineActive(Ref ref) {
  final isPro = ref.watch(proControllerProvider);
  return isPro && ref.read(proControllerProvider.notifier).offlineEnabled;
}

Future<List<T>?> _cachedList<T>(
  Ref ref,
  String bucket,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final account = ref.watch(activeAccountProvider);
  if (account == null || !_offlineActive(ref)) return null;
  final raw = await ref.read(offlineCacheProvider).getJson(account.id, bucket);
  if (raw is! List) return null;
  return raw
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

Future<void> _putList(
  Ref ref,
  String bucket,
  List<Map<String, dynamic>> rows,
) async {
  final account = ref.watch(activeAccountProvider);
  if (account == null || !_offlineActive(ref)) return;
  await ref.read(offlineCacheProvider).putJson(account.id, bucket, rows);
  await ref.read(offlineWriteCoordinatorProvider).drain();
}

final tasksProvider = FutureProvider.family<List<TududiTask>, TaskListFilter>((
  ref,
  filter,
) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];

  try {
    final List<TududiTask> tasks;
    if (filter == TaskListFilter.today) {
      tasks = await fetchTodayTasks(client);
    } else {
      final type = switch (filter) {
        TaskListFilter.upcoming => 'upcoming',
        TaskListFilter.inbox => 'inbox',
        TaskListFilter.someday => 'someday',
        TaskListFilter.all => null,
        TaskListFilter.today => 'today',
      };
      tasks = excludeSubtasks(await client.listTasks(type: type));
    }
    await _putList(
      ref,
      'tasks_${filter.name}',
      tasks.map(_taskListCacheJson).toList(),
    );
    return tasks;
  } catch (e) {
    final cached = await _cachedList(
      ref,
      'tasks_${filter.name}',
      TududiTask.fromJson,
    );
    if (cached != null) return cached;
    rethrow;
  }
});

final taskDetailProvider = FutureProvider.family<TududiTask, String>((
  ref,
  uid,
) async {
  final client = await ref.watch(tududiClientProvider.future);
  try {
    if (client == null) {
      throw TududiApiException(message: 'Not signed in');
    }
    return await client.getTask(uid);
  } catch (e) {
    if (!_offlineActive(ref)) rethrow;
    final account = ref.watch(activeAccountProvider);
    if (account == null) rethrow;
    final cache = ref.read(offlineCacheProvider);
    for (final filter in TaskListFilter.values) {
      final raw = await cache.getJson(account.id, 'tasks_${filter.name}');
      if (raw is! List) continue;
      for (final item in raw.whereType<Map>()) {
        final task = TududiTask.fromJson(Map<String, dynamic>.from(item));
        if (task.uid == uid) return task;
      }
    }
    rethrow;
  }
});

final tagsProvider = FutureProvider<List<TududiTag>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  try {
    return await client.listTags();
  } catch (_) {
    return const [];
  }
});

final projectsProvider = FutureProvider<List<TududiProject>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  try {
    final projects = await client.listProjects();
    await _putList(ref, 'projects', projects.map((p) => p.toJson()).toList());
    return projects;
  } catch (e) {
    final cached = await _cachedList(ref, 'projects', TududiProject.fromJson);
    if (cached != null) return cached;
    rethrow;
  }
});

final areasProvider = FutureProvider<List<TududiArea>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  try {
    final areas = await client.listAreas();
    await _putList(ref, 'areas', areas.map((a) => a.toJson()).toList());
    return areas;
  } catch (e) {
    final cached = await _cachedList(ref, 'areas', TududiArea.fromJson);
    if (cached != null) return cached;
    rethrow;
  }
});

final notesProvider = FutureProvider<List<TududiNote>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  try {
    final notes = await client.listNotes();
    await _putList(
      ref,
      'notes',
      notes
          .map(
            (n) => {
              'id': n.id,
              'uid': n.uid,
              'title': n.title,
              if (n.content != null) 'content': n.content,
              if (n.updatedAt != null) 'updated_at': n.updatedAt,
              if (n.projectId != null) 'project_id': n.projectId,
              if (n.projectUid != null) 'project_uid': n.projectUid,
            },
          )
          .toList(),
    );
    return notes;
  } catch (e) {
    final cached = await _cachedList(ref, 'notes', TududiNote.fromJson);
    if (cached != null) return cached;
    rethrow;
  }
});

final goalsProvider = FutureProvider<List<TududiGoal>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  try {
    final goals = await client.listGoals();
    await _putList(
      ref,
      'goals',
      goals
          .map(
            (g) => {
              'id': g.id,
              'uid': g.uid,
              'title': g.title,
              if (g.why != null) 'why': g.why,
              'horizon': g.horizon,
              if (g.targetDate != null) 'target_date': g.targetDate,
              'status': g.status,
            },
          )
          .toList(),
    );
    return goals;
  } catch (e) {
    final cached = await _cachedList(ref, 'goals', TududiGoal.fromJson);
    if (cached != null) return cached;
    rethrow;
  }
});

final habitsProvider = FutureProvider<List<TududiHabit>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  try {
    final habits = await client.listHabits();
    await _putList(
      ref,
      'habits',
      habits
          .map(
            (h) => {
              'id': h.id,
              'uid': h.uid,
              'name': h.name,
              'streak': h.streak,
              'completed_today': h.completedToday,
            },
          )
          .toList(),
    );
    return habits;
  } catch (e) {
    final cached = await _cachedList(ref, 'habits', TududiHabit.fromJson);
    if (cached != null) return cached;
    rethrow;
  }
});
