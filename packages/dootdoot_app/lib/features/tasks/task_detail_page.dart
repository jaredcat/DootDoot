import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/feedback/completion_sound.dart';
import '../../core/edit_history/edit_commands.dart';
import '../../core/edit_history/edit_history.dart';
import '../../core/edit_history/edit_overlay.dart';
import '../../core/offline/offline_write_coordinator.dart';
import 'recurrence_picker.dart';
import 'task_actions.dart';
import 'task_providers.dart';
import 'task_status_display.dart';

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
  /// Local switch value so the Completed toggle flips before the network returns.
  bool? _completedOverride;

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
    invalidateAllTaskLists(ref, detailUid: widget.uid);
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
          if (task.projectId != null) 'project_id': task.projectId,
          if (task.projectUid != null) 'project_uid': task.projectUid,
        },
        current: task,
      );
      ref.read(editHistoryProvider.notifier).push(
            TaskUpdateCommand(before: task, after: result.value),
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

  Future<void> _toggleDone(TududiTask task, bool done) async {
    if (done) playCompletionSound();
    final before =
        task.uid == widget.uid ? task : task.copyWith(uid: widget.uid);
    final optimistic = before.copyWith(
      status: done ? TaskStatus.done : TaskStatus.notStarted,
    );
    // Flip the switch and Status row immediately — don't wait on the network.
    setState(() => _completedOverride = done);
    ref.read(editOverlayProvider.notifier).setTask(widget.uid, optimistic);

    try {
      final result =
          await ref.read(offlineWriteCoordinatorProvider).completeTask(
                widget.uid,
                done: done,
                current: before,
              );
      var after = result.value.uid == widget.uid
          ? result.value
          : result.value.copyWith(uid: widget.uid);

      // Recurring templates: tududi logs the completion then advances the same
      // task to the next due date with status back to not-started.
      if (done && !after.isDone) {
        if (mounted) {
          setState(() => _completedOverride = false);
          showTaskCompleteSnackBar(
            context,
            requestedDone: done,
            after: after,
            result: result,
          );
        }
        ref.read(editHistoryProvider.notifier).push(
              TaskUpdateCommand(before: before, after: after),
            );
        return;
      }

      if (after.isDone != done) {
        after = after.copyWith(
          status: done ? TaskStatus.done : TaskStatus.notStarted,
        );
      }
      ref.read(editHistoryProvider.notifier).push(
            TaskUpdateCommand(before: before, after: after),
          );
      if (mounted) {
        setState(() => _completedOverride = after.isDone);
        showTaskCompleteSnackBar(
          context,
          requestedDone: done,
          after: after,
          result: result,
        );
      }
    } catch (e) {
      ref.read(editOverlayProvider.notifier).setTask(widget.uid, before);
      if (mounted) {
        setState(() => _completedOverride = before.isDone);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      _invalidateTaskLists();
    }
  }

  Future<void> _patch(
    TududiTask task,
    Map<String, dynamic> body, {
    String? successMessage,
  }) async {
    setState(() => _saving = true);
    try {
      await patchTaskFields(
        context,
        ref,
        task,
        body: {
          'name': _nameController.text.trim(),
          'note': _noteController.text.trim(),
          ...body,
        },
        successMessage: successMessage,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickRecurrence(TududiTask task) async {
    final draft = await showRecurrencePicker(context, task: task);
    if (draft == null || !mounted) return;
    final label = draft.previewLabel;
    await _patch(
      task,
      draft.toPatchBody(),
      successMessage: draft.isActive ? 'Repeats: $label' : 'Does not repeat',
    );
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
                      ? const Icon(Symbols.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      if (selected == TaskStatus.done && !task.isDone) {
        playCompletionSound();
      }
      await _patch(task, {'status': selected});
    }
  }

  Future<void> _pickDue(TududiTask task) async {
    final selected = await showModalBottomSheet<String>(
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
                  'Due',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Symbols.today),
                title: const Text('Today'),
                onTap: () => Navigator.of(context).pop('today'),
              ),
              ListTile(
                leading: const Icon(Symbols.event),
                title: const Text('Tomorrow'),
                onTap: () => Navigator.of(context).pop('tomorrow'),
              ),
              ListTile(
                leading: const Icon(Symbols.calendar_month),
                title: const Text('Pick date…'),
                onTap: () => Navigator.of(context).pop('pick'),
              ),
              ListTile(
                leading: const Icon(Symbols.beach_access),
                title: const Text('Clear due'),
                onTap: () => Navigator.of(context).pop('clear'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;

    switch (selected) {
      case 'today':
        await _patch(
          task,
          {'due_date': todayYmd()},
          successMessage: 'Due today',
        );
      case 'tomorrow':
        await _patch(
          task,
          {'due_date': tomorrowYmd()},
          successMessage: 'Due tomorrow',
        );
      case 'clear':
        await _patch(
          task,
          {'due_date': null},
          successMessage: 'Due date cleared',
        );
      case 'pick':
        final now = DateTime.now();
        final initial = _parseDue(task.dueDate) ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null && mounted) {
          await _patch(
            task,
            {'due_date': formatDateYmd(picked)},
            successMessage: 'Due ${formatDateYmd(picked)}',
          );
        }
    }
  }

  DateTime? _parseDue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _pickPriority(TududiTask task) async {
    final selected = await showPriorityPicker(
      context,
      current: task.priority,
    );
    if (selected != null && mounted) {
      await _patch(
        task,
        {'priority': selected},
        successMessage: 'Priority: ${priorityLabel(selected)}',
      );
    }
  }

  Future<void> _pickProject(TududiTask task) async {
    final projects = await ref.read(projectsProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<Object>(
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
                  'Project',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                title: const Text('Inbox (no project)'),
                trailing: task.projectId == null && task.projectUid == null
                    ? const Icon(Symbols.check)
                    : null,
                onTap: () => Navigator.of(context).pop('inbox'),
              ),
              for (final project in projects)
                ListTile(
                  title: Text(project.name),
                  trailing: (project.uid != null &&
                              project.uid == task.projectUid) ||
                          project.id == task.projectId
                      ? const Icon(Symbols.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(project),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;

    if (selected == 'inbox') {
      await _patch(
        task,
        {
          'project_id': null,
          'project_uid': null,
          'project_name': null,
        },
        successMessage: 'Moved to Inbox',
      );
      return;
    }

    if (selected is TududiProject) {
      await _patch(
        task,
        {
          'project_id': selected.id,
          if (selected.uid != null) 'project_uid': selected.uid,
          'project_name': selected.name,
        },
        successMessage: 'Moved to ${selected.name}',
      );
    }
  }

  Future<void> _delete(TududiTask task) async {
    await deleteTaskWithConfirm(
      context,
      ref,
      task,
      onDeleted: () {
        if (mounted) context.pop();
      },
    );
  }

  String _dueSubtitle(TududiTask task) {
    if (task.dueDate == null || task.dueDate!.isEmpty) return 'None';
    return [
      task.dueDate,
      if (task.dueTime != null) task.dueTime,
    ].whereType<String>().join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskDetailProvider(widget.uid));
    final overlay = ref.watch(editOverlayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          async.maybeWhen(
            data: (task) => PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _delete(overlayTaskOr(widget.uid, task, overlay) ?? task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          async.maybeWhen(
            data: (task) => IconButton(
              onPressed: _saving ? null : () => _save(task),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.check),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (rawTask) {
          final task = overlayTaskOr(widget.uid, rawTask, overlay) ?? rawTask;
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
                value: _completedOverride ?? task.isDone,
                onChanged:
                    _saving ? null : (value) => _toggleDone(task, value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Status'),
                subtitle: Text(
                  TaskStatus.label(
                    (_completedOverride ?? task.isDone)
                        ? TaskStatus.done
                        : (_completedOverride == false
                            ? TaskStatus.notStarted
                            : task.status),
                  ),
                ),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _saving ? null : () => _pickStatus(task),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due'),
                subtitle: Text(_dueSubtitle(task)),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _saving ? null : () => _pickDue(task),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat'),
                subtitle: Text(recurrenceLabel(task) ?? 'Does not repeat'),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _saving ? null : () => _pickRecurrence(task),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Priority'),
                subtitle: Text(priorityLabel(task.priority)),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _saving ? null : () => _pickPriority(task),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Project'),
                subtitle: Text(
                  task.projectName?.isNotEmpty == true
                      ? task.projectName!
                      : 'Inbox',
                ),
                trailing: const Icon(Symbols.chevron_right),
                onTap: _saving ? null : () => _pickProject(task),
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
                          ? Symbols.check_box
                          : Symbols.check_box_outline_blank,
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
