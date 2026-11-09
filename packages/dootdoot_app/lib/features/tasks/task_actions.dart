import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/edit_history/edit_commands.dart';
import '../../core/edit_history/edit_history.dart';
import '../../core/offline/offline_write_coordinator.dart';
import 'task_providers.dart';
import 'task_status_display.dart';

/// Snackbar after complete/uncomplete (incl. recurring next-due).
void showTaskCompleteSnackBar(
  BuildContext context, {
  required bool requestedDone,
  required TududiTask after,
  OfflineMutationResult<dynamic>? result,
}) {
  final msg = snackMessageForTaskComplete(
    requestedDone: requestedDone,
    after: after,
    offlineQueued: result == null ? null : offlineQueuedMessage(result),
  );
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

const taskPriorityChoices = ['low', 'medium', 'high'];

String priorityLabel(String? priority) {
  return switch (priority) {
    'high' || '2' => 'High',
    'medium' || '1' => 'Medium',
    'low' || '0' => 'Low',
    _ => 'None',
  };
}

bool _priorityMatches(String choice, String? current) {
  return switch (choice) {
    'low' => current == 'low' || current == '0' || current == null,
    'medium' => current == 'medium' || current == '1',
    'high' => current == 'high' || current == '2',
    _ => false,
  };
}

/// Floating dialog to choose Low / Medium / High. Returns null if dismissed.
Future<String?> showPriorityPicker(
  BuildContext context, {
  String? current,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Priority'),
        contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final priority in taskPriorityChoices)
              ListTile(
                title: Text(priorityLabel(priority)),
                trailing: _priorityMatches(priority, current)
                    ? const Icon(Symbols.check)
                    : null,
                onTap: () => Navigator.of(context).pop(priority),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

Future<void> pickAndSetTaskPriority(
  BuildContext context,
  WidgetRef ref,
  TududiTask task, {
  VoidCallback? onDone,
}) async {
  final selected = await showPriorityPicker(
    context,
    current: task.priority,
  );
  if (selected == null || !context.mounted) return;
  await patchTaskFields(
    context,
    ref,
    task,
    body: {'priority': selected},
    successMessage: 'Priority: ${priorityLabel(selected)}',
    onDone: onDone,
  );
}

String formatDateYmd(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String todayYmd() => formatDateYmd(DateTime.now());

String tomorrowYmd() =>
    formatDateYmd(DateTime.now().add(const Duration(days: 1)));

void invalidateAllTaskLists(WidgetRef ref, {String? detailUid}) {
  if (detailUid != null) {
    ref.invalidate(taskDetailProvider(detailUid));
  }
  for (final filter in TaskListFilter.values) {
    ref.invalidate(tasksProvider(filter));
  }
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  String? body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<void> patchTaskFields(
  BuildContext context,
  WidgetRef ref,
  TududiTask task, {
  required Map<String, dynamic> body,
  String? successMessage,
  VoidCallback? onDone,
}) async {
  final uid = task.uid;
  if (uid == null) return;
  try {
    final patchBody = {
      'name': task.displayName,
      'note': task.note,
      'status': task.status,
      'priority': task.priority,
      'due_date': task.dueDate,
      if (task.projectId != null) 'project_id': task.projectId,
      if (task.projectUid != null) 'project_uid': task.projectUid,
      ...body,
    };
    final result = await ref.read(offlineWriteCoordinatorProvider).updateTask(
          uid,
          patchBody,
          current: task,
        );
    final after = result.value;
    ref.read(editHistoryProvider.notifier).push(
          TaskUpdateCommand(before: task, after: after),
        );
    invalidateAllTaskLists(ref, detailUid: uid);
    onDone?.call();
    if (!context.mounted) return;
    final offlineMsg = offlineQueuedMessage(result);
    final msg = offlineMsg ?? successMessage;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

Future<void> deleteTaskWithConfirm(
  BuildContext context,
  WidgetRef ref,
  TududiTask task, {
  VoidCallback? onDeleted,
}) async {
  final uid = task.uid;
  if (uid == null) return;
  final ok = await confirmDelete(
    context,
    title: 'Delete task?',
    body: task.displayName,
  );
  if (!ok || !context.mounted) return;
  try {
    final result = await ref.read(offlineWriteCoordinatorProvider).deleteTask(
          uid,
          current: task,
        );
    ref.read(editHistoryProvider.notifier).push(TaskDeleteCommand(task));
    invalidateAllTaskLists(ref, detailUid: uid);
    onDeleted?.call();
    if (!context.mounted) return;
    final msg = offlineQueuedMessage(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? 'Deleted')),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
