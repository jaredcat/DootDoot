import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:flutter/material.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/widgets/swipe_action_tile.dart';

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

    final tile = ListTile(
      leading: IconButton(
        onPressed: onToggle,
        icon: Icon(
          task.isDone ? Icons.check_circle : Icons.circle_outlined,
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
      trailing: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
      ),
      onTap: onOpen,
    );

    final actions = <SwipeAction>[
      if (onDueToday != null)
        SwipeAction(
          label: 'Today',
          icon: Icons.today_outlined,
          onPressed: onDueToday!,
          backgroundColor: DootColors.sea,
          foregroundColor: Colors.white,
        ),
      if (onPickPriority != null)
        SwipeAction(
          label: 'Priority',
          icon: Icons.flag_outlined,
          onPressed: onPickPriority!,
          backgroundColor: DootColors.amber,
          foregroundColor: Colors.white,
        ),
      if (onDelete != null)
        SwipeAction(
          label: 'Delete',
          icon: Icons.delete_outline,
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
    final parts = <String>[
      if (task.projectName != null && task.projectName!.isNotEmpty)
        task.projectName!,
      if (task.dueDate != null && task.dueDate!.isNotEmpty) task.dueDate!,
    ];
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}
