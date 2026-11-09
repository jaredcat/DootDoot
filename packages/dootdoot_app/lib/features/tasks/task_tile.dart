import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:flutter/material.dart';
import 'package:tududi_api/tududi_api.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
  });

  final TududiTask task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      'high' || '2' => DootColors.coral,
      'medium' || '1' => DootColors.amber,
      'low' || '0' => DootColors.moss,
      _ => Theme.of(context).colorScheme.outline,
    };

    return ListTile(
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
