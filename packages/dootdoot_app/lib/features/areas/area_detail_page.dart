import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/offline/offline_write_coordinator.dart';
import '../../core/providers.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_tile.dart';

final areaDetailProvider =
    FutureProvider.family<(TududiArea, List<TududiTask>), String>((
  ref,
  uid,
) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) {
    throw TududiApiException(message: 'Not signed in');
  }
  final areas = await client.listAreas();
  TududiArea? area;
  for (final a in areas) {
    if (a.uid == uid) {
      area = a;
      break;
    }
  }
  if (area == null) {
    throw TududiApiException(message: 'Area not found');
  }
  var tasks = await client.listTasks(areaUid: uid);
  if (tasks.isEmpty) {
    // Fallback if server ignores area_uid: filter client-side.
    final all = await client.listTasks();
    tasks = all.where((t) => t.areaUid == uid).toList();
  }
  return (area, tasks);
});

class AreaDetailPage extends ConsumerWidget {
  const AreaDetailPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(areaDetailProvider(uid));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (data) {
        final area = data.$1;
        final tasks = data.$2;
        return Scaffold(
          appBar: AppBar(title: Text(area.name)),
          body: RefreshIndicator(
            onRefresh: () async => ref.invalidate(areaDetailProvider(uid)),
            child: ListView(
              children: [
                if (area.description != null &&
                    area.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(area.description!),
                  ),
                const Divider(),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No tasks in this area')),
                  ),
                ...tasks.map(
                  (task) => TaskTile(
                    task: task,
                    onToggle: () async {
                      final taskUid = task.uid;
                      if (taskUid == null) return;
                      final result = await ref
                          .read(offlineWriteCoordinatorProvider)
                          .completeTask(
                            taskUid,
                            done: !task.isDone,
                            current: task,
                          );
                      ref.invalidate(areaDetailProvider(uid));
                      final msg = offlineQueuedMessage(result);
                      if (msg != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    },
                    onOpen: () {
                      final taskUid = task.uid;
                      if (taskUid != null) context.push('/task/$taskUid');
                    },
                    onDelete: () => deleteTaskWithConfirm(
                      context,
                      ref,
                      task,
                      onDeleted: () => ref.invalidate(areaDetailProvider(uid)),
                    ),
                    onDueToday: () => patchTaskFields(
                      context,
                      ref,
                      task,
                      body: {'due_date': todayYmd()},
                      successMessage: 'Due today',
                      onDone: () => ref.invalidate(areaDetailProvider(uid)),
                    ),
                    onPickPriority: () => pickAndSetTaskPriority(
                      context,
                      ref,
                      task,
                      onDone: () => ref.invalidate(areaDetailProvider(uid)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
