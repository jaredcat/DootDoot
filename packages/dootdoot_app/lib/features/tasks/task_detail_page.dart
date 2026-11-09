import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/providers.dart';
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

  Future<void> _save(TududiTask task) async {
    final client = await ref.read(tududiClientProvider.future);
    if (client == null) return;
    setState(() => _saving = true);
    try {
      await client.updateTask(widget.uid, {
        'name': _nameController.text.trim(),
        'note': _noteController.text.trim(),
        'status': task.status,
        'priority': task.priority,
        'due_date': task.dueDate,
      });
      ref.invalidate(taskDetailProvider(widget.uid));
      ref.invalidate(tasksProvider(TaskListFilter.today));
      ref.invalidate(tasksProvider(TaskListFilter.upcoming));
      ref.invalidate(tasksProvider(TaskListFilter.inbox));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
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
    final client = await ref.read(tududiClientProvider.future);
    if (client == null) return;
    await client.completeTask(widget.uid, done: !task.isDone);
    ref.invalidate(taskDetailProvider(widget.uid));
    ref.invalidate(tasksProvider(TaskListFilter.today));
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
