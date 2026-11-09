import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/offline/offline_write_coordinator.dart';
import '../../core/providers.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_tile.dart';

final projectDetailProvider =
    FutureProvider.family<(TududiProject, List<TududiTask>), String>((
      ref,
      uid,
    ) async {
      final client = await ref.watch(tududiClientProvider.future);
      if (client == null) {
        throw TududiApiException(message: 'Not signed in');
      }
      final project = await client.getProject(uid);
      final tasks = await client.listTasks(projectUid: uid);
      return (project, tasks);
    });

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectDetailProvider(uid));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (data) {
        final project = data.$1;
        final tasks = data.$2;
        return Scaffold(
          appBar: AppBar(title: Text(project.name)),
          body: RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectDetailProvider(uid)),
            child: ListView(
              children: [
                if (project.description != null &&
                    project.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(project.description!),
                  ),
                const Divider(),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No tasks in this project')),
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
                      ref.invalidate(projectDetailProvider(uid));
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
                      onDeleted: () =>
                          ref.invalidate(projectDetailProvider(uid)),
                    ),
                    onDueToday: () => patchTaskFields(
                      context,
                      ref,
                      task,
                      body: {'due_date': todayYmd()},
                      successMessage: 'Due today',
                      onDone: () =>
                          ref.invalidate(projectDetailProvider(uid)),
                    ),
                    onPickPriority: () => pickAndSetTaskPriority(
                      context,
                      ref,
                      task,
                      onDone: () =>
                          ref.invalidate(projectDetailProvider(uid)),
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
