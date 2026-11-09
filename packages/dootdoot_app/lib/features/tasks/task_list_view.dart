import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/providers.dart';
import 'task_providers.dart';
import 'task_tile.dart';

export 'task_providers.dart' show TaskListFilter;

class TaskListView extends ConsumerWidget {
  const TaskListView({super.key, required this.filter});

  final TaskListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksProvider(filter));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorPane(
        message: e.toString(),
        onRetry: () => ref.invalidate(tasksProvider(filter)),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tasksProvider(filter)),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  _emptyLabel(filter),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tasksProvider(filter)),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskTile(
                task: task,
                onToggle: () => _toggle(ref, task),
                onOpen: () {
                  final uid = task.uid;
                  if (uid != null) context.push('/task/$uid');
                },
              );
            },
          ),
        );
      },
    );
  }

  String _emptyLabel(TaskListFilter filter) {
    return switch (filter) {
      TaskListFilter.today => 'Nothing for today',
      TaskListFilter.upcoming => 'No upcoming tasks',
      TaskListFilter.inbox => 'Inbox is clear',
      TaskListFilter.someday => 'No someday tasks',
      TaskListFilter.all => 'No tasks yet',
    };
  }

  Future<void> _toggle(WidgetRef ref, TududiTask task) async {
    final client = await ref.read(tududiClientProvider.future);
    final uid = task.uid;
    if (client == null || uid == null) return;
    await client.completeTask(uid, done: !task.isDone);
    ref.invalidate(tasksProvider(filter));
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
