import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/offline/offline_write_coordinator.dart';
import 'task_providers.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  const TaskDetailPage({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static const _statusChoices = [
    TaskStatus.notStarted,
    TaskStatus.inProgress,
    TaskStatus.waiting,
    TaskStatus.planned,
    TaskStatus.done,
    TaskStatus.archived,
    TaskStatus.cancelled,
  ];

  void _invalidateTaskLists() {
    ref.invalidate(taskDetailProvider(widget.uid));
    ref.invalidate(tasksProvider(TaskListFilter.today));
    ref.invalidate(tasksProvider(TaskListFilter.upcoming));
    ref.invalidate(tasksProvider(TaskListFilter.inbox));
    ref.invalidate(tasksProvider(TaskListFilter.all));
  }

  Future<void> _save(TududiTask task) async {
    setState(() => _saving = true);
    try {
      final result =
          await ref.read(offlineWriteCoordinatorProvider).updateTask(
        widget.uid,
        {
          'name': _nameController.text.trim(),
          'note': _noteController.text.trim(),
          'status': task.status,
          'priority': task.priority,
          'due_date': task.dueDate,
        },
        current: task,
      );
      _invalidateTaskLists();
      if (mounted) {
        final offlineMsg = offlineQueuedMessage(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(offlineMsg ?? 'Saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleDone(TududiTask task) async {
    final result = await ref.read(offlineWriteCoordinatorProvider).completeTask(
          widget.uid,
          done: !task.isDone,
          current: task,
        );
    _invalidateTaskLists();
    final msg = offlineQueuedMessage(result);
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _setStatus(TududiTask task, int status) async {
    if (status == task.status) return;
    setState(() => _saving = true);
    try {
      final result =
          await ref.read(offlineWriteCoordinatorProvider).updateTask(
        widget.uid,
        {
          'name': _nameController.text.trim(),
          'note': _noteController.text.trim(),
          'status': status,
          'priority': task.priority,
          'due_date': task.dueDate,
        },
        current: task,
      );
      _invalidateTaskLists();
      if (mounted) {
        final offlineMsg = offlineQueuedMessage(result);
        if (offlineMsg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(offlineMsg)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickStatus(TududiTask task) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final status in _statusChoices)
                ListTile(
                  title: Text(TaskStatus.label(status)),
                  trailing: status == task.status
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      await _setStatus(task, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskDetailProvider(widget.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          async.maybeWhen(
            data: (task) => IconButton(
              onPressed: _saving ? null : () => _save(task),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (task) {
          if (!_initialized) {
            _nameController.text = task.displayName;
            _noteController.text = task.note ?? '';
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameController,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Task name',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Completed'),
                value: task.isDone,
                onChanged: (_) => _toggleDone(task),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Status'),
                subtitle: Text(TaskStatus.label(task.status)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _saving ? null : () => _pickStatus(task),
              ),
              if (task.dueDate != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due'),
                  subtitle: Text(
                    [
                      task.dueDate,
                      if (task.dueTime != null) task.dueTime,
                    ].whereType<String>().join(' '),
                  ),
                ),
              if (task.projectName != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Project'),
                  subtitle: Text(task.projectName!),
                ),
              if (task.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: task.tags
                      .map((t) => Chip(label: Text(t.name)))
                      .toList(),
                ),
              const SizedBox(height: 12),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              TextField(
                controller: _noteController,
                maxLines: 8,
                decoration: const InputDecoration(hintText: 'Add details…'),
              ),
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Subtasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...task.subtasks.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      s.isDone
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    title: Text(s.displayName),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
