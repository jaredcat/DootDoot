import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/widgets/swipe_action_tile.dart';
import 'task_status_display.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
    this.onDelete,
    this.onDueToday,
    this.onPickPriority,
  });

  final TududiTask task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onDueToday;
  final VoidCallback? onPickPriority;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      'high' || '2' => DootColors.coral,
      'medium' || '1' => DootColors.amber,
      'low' || '0' => DootColors.moss,
      _ => Theme.of(context).colorScheme.outline,
    };
    final statusIcons = taskStatusIcons(task);
    final outline = Theme.of(context).colorScheme.outline;

    final tile = ListTile(
      leading: IconButton(
        onPressed: onToggle,
        icon: Icon(
          task.isDone ? Symbols.check_circle : Symbols.circle,
          fill: task.isDone ? 1 : 0,
          color: task.isDone
              ? DootColors.moss
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      title: Text(
        task.displayName,
        style: TextStyle(
          decoration: task.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: _subtitle(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final icon in statusIcons) ...[
            Icon(
              icon,
              size: 16,
              color: icon == Symbols.warning_amber
                  ? DootColors.coral
                  : outline,
            ),
            const SizedBox(width: 6),
          ],
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      onTap: onOpen,
    );

    final actions = <SwipeAction>[
      if (onDueToday != null)
        SwipeAction(
          label: 'Today',
          icon: Symbols.today,
          onPressed: onDueToday!,
          backgroundColor: DootColors.sea,
          foregroundColor: Colors.white,
        ),
      if (onPickPriority != null)
        SwipeAction(
          label: 'Priority',
          icon: Symbols.flag,
          onPressed: onPickPriority!,
          backgroundColor: DootColors.amber,
          foregroundColor: Colors.white,
        ),
      if (onDelete != null)
        SwipeAction(
          label: 'Delete',
          icon: Symbols.delete,
          onPressed: onDelete!,
          backgroundColor: DootColors.coral,
          foregroundColor: Colors.white,
        ),
    ];

    if (actions.isEmpty) return tile;
    return SwipeActionTile(
      key: ValueKey('task-swipe-${task.uid ?? task.id}'),
      actions: actions,
      child: tile,
    );
  }

  Widget? _subtitle(BuildContext context) {
    final project = task.projectName;
    final due = task.dueDate;
    // Icons cover overdue + repeating; spell out only project, due, workflow.
    final parts = <String>[
      if (project != null && project.isNotEmpty) project,
      if (due != null && due.isNotEmpty) due,
      ?workflowStatusLabel(task),
    ];
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}
