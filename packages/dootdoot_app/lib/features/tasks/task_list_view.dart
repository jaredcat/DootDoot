import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/offline/offline_write_coordinator.dart';
import 'task_actions.dart';
import 'task_list_organize.dart';
import 'task_providers.dart';
import 'task_tile.dart';

export 'task_providers.dart' show TaskListFilter;

/// Persists Upcoming Active/Completed/All for the session.
final upcomingStatusFilterProvider =
    NotifierProvider<UpcomingStatusFilterNotifier, UpcomingStatusFilter>(
  UpcomingStatusFilterNotifier.new,
);

class UpcomingStatusFilterNotifier extends Notifier<UpcomingStatusFilter> {
  @override
  UpcomingStatusFilter build() => UpcomingStatusFilter.active;

  void setFilter(UpcomingStatusFilter value) => state = value;
}

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
        return switch (filter) {
          TaskListFilter.today => _TodayTaskList(
              tasks: tasks,
              onRefresh: () async {
                ref.invalidate(tasksProvider(filter));
              },
              onToggle: (task) => _toggle(context, ref, task),
              onDelete: (task) => deleteTaskWithConfirm(context, ref, task),
              onDueToday: (task) => patchTaskFields(
                context,
                ref,
                task,
                body: {'due_date': todayYmd()},
                successMessage: 'Due today',
              ),
              onPickPriority: (task) =>
                  pickAndSetTaskPriority(context, ref, task),
            ),
          TaskListFilter.upcoming => _UpcomingTaskList(
              tasks: tasks,
              onRefresh: () async {
                ref.invalidate(tasksProvider(filter));
              },
              onToggle: (task) => _toggle(context, ref, task),
              onDelete: (task) => deleteTaskWithConfirm(context, ref, task),
              onDueToday: (task) => patchTaskFields(
                context,
                ref,
                task,
                body: {'due_date': todayYmd()},
                successMessage: 'Due today',
              ),
              onPickPriority: (task) =>
                  pickAndSetTaskPriority(context, ref, task),
            ),
          _ => _FlatTaskList(
              tasks: tasks,
              emptyLabel: _emptyLabel(filter),
              onRefresh: () async {
                ref.invalidate(tasksProvider(filter));
              },
              onToggle: (task) => _toggle(context, ref, task),
              onDelete: (task) => deleteTaskWithConfirm(context, ref, task),
              onDueToday: (task) => patchTaskFields(
                context,
                ref,
                task,
                body: {'due_date': todayYmd()},
                successMessage: 'Due today',
              ),
              onPickPriority: (task) =>
                  pickAndSetTaskPriority(context, ref, task),
            ),
        };
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

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    TududiTask task,
  ) async {
    final uid = task.uid;
    if (uid == null) return;
    final result = await ref.read(offlineWriteCoordinatorProvider).completeTask(
          uid,
          done: !task.isDone,
          current: task,
        );
    ref.invalidate(tasksProvider(filter));
    final msg = offlineQueuedMessage(result);
    if (msg != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _FlatTaskList extends StatelessWidget {
  const _FlatTaskList({
    required this.tasks,
    required this.emptyLabel,
    required this.onRefresh,
    required this.onToggle,
    required this.onDelete,
    required this.onDueToday,
    required this.onPickPriority,
  });

  final List<TududiTask> tasks;
  final String emptyLabel;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TududiTask task) onToggle;
  final Future<void> Function(TududiTask task) onDelete;
  final Future<void> Function(TududiTask task) onDueToday;
  final Future<void> Function(TududiTask task) onPickPriority;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _EmptyRefreshList(label: emptyLabel, onRefresh: onRefresh);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskTile(
            task: task,
            onToggle: () => onToggle(task),
            onOpen: () {
              final uid = task.uid;
              if (uid != null) context.push('/task/$uid');
            },
            onDelete: () => onDelete(task),
            onDueToday: () => onDueToday(task),
            onPickPriority: () => onPickPriority(task),
          );
        },
      ),
    );
  }
}

class _TodayTaskList extends StatelessWidget {
  const _TodayTaskList({
    required this.tasks,
    required this.onRefresh,
    required this.onToggle,
    required this.onDelete,
    required this.onDueToday,
    required this.onPickPriority,
  });

  final List<TududiTask> tasks;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TududiTask task) onToggle;
  final Future<void> Function(TududiTask task) onDelete;
  final Future<void> Function(TududiTask task) onDueToday;
  final Future<void> Function(TududiTask task) onPickPriority;

  @override
  Widget build(BuildContext context) {
    final sections = organizeTodaySections(tasks);
    if (sections.isEmpty) {
      return _EmptyRefreshList(
        label: 'Nothing for today',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final section in sections) ...[
            _SectionHeader(title: section.title, count: section.tasks.length),
            ...section.tasks.map(
              (task) => TaskTile(
                task: task,
                onToggle: () => onToggle(task),
                onOpen: () {
                  final uid = task.uid;
                  if (uid != null) context.push('/task/$uid');
                },
                onDelete: () => onDelete(task),
                onDueToday: () => onDueToday(task),
                onPickPriority: () => onPickPriority(task),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingTaskList extends ConsumerWidget {
  const _UpcomingTaskList({
    required this.tasks,
    required this.onRefresh,
    required this.onToggle,
    required this.onDelete,
    required this.onDueToday,
    required this.onPickPriority,
  });

  final List<TududiTask> tasks;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TududiTask task) onToggle;
  final Future<void> Function(TududiTask task) onDelete;
  final Future<void> Function(TududiTask task) onDueToday;
  final Future<void> Function(TududiTask task) onPickPriority;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(upcomingStatusFilterProvider);
    final sections = organizeUpcomingSections(
      tasks,
      statusFilter: statusFilter,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SegmentedButton<UpcomingStatusFilter>(
            // The check icon makes "Completed" wrap onto a second line.
            showSelectedIcon: false,
            segments: [
              for (final value in UpcomingStatusFilter.values)
                ButtonSegment(
                  value: value,
                  label: Text(value.label, maxLines: 1),
                ),
            ],
            selected: {statusFilter},
            onSelectionChanged: (next) {
              ref
                  .read(upcomingStatusFilterProvider.notifier)
                  .setFilter(next.first);
            },
          ),
        ),
        Expanded(
          child: sections.isEmpty
              ? _EmptyRefreshList(
                  label: switch (statusFilter) {
                    UpcomingStatusFilter.active => 'No upcoming tasks',
                    UpcomingStatusFilter.completed =>
                      'No completed tasks this week',
                    UpcomingStatusFilter.all => 'No upcoming tasks',
                  },
                  onRefresh: onRefresh,
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final section in sections) ...[
                        _SectionHeader(
                          title: section.title,
                          count: section.tasks.length,
                        ),
                        ...section.tasks.map(
                          (task) => TaskTile(
                            task: task,
                            onToggle: () => onToggle(task),
                            onOpen: () {
                              final uid = task.uid;
                              if (uid != null) context.push('/task/$uid');
                            },
                            onDelete: () => onDelete(task),
                            onDueToday: () => onDueToday(task),
                            onPickPriority: () => onPickPriority(task),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRefreshList extends StatelessWidget {
  const _EmptyRefreshList({required this.label, required this.onRefresh});

  final String label;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
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
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
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
