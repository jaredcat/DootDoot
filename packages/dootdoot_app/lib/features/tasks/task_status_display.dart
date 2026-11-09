import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tududi_api/tududi_api.dart';

import 'task_list_organize.dart';

const _weekdayShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _weekdayLong = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/// Whether [task] is open and due before today (calendar day).
bool isTaskOverdue(TududiTask task, [DateTime? now]) {
  if (!task.isOpen) return false;
  final due = taskDueDay(task);
  if (due == null) return false;
  return due.isBefore(calendarDay(now));
}

/// Human-readable recurrence, e.g. `Every week on Mon, Wed`.
String? recurrenceLabel(TududiTask task) {
  if (!task.isRecurring) return null;
  final interval = task.recurrenceInterval ?? 1;
  final type = task.recurrenceType!;

  String every(String unit, String plural) {
    if (interval <= 1) return 'Every $unit';
    return 'Every $interval $plural';
  }

  final String base;
  switch (type) {
    case RecurrenceType.daily:
      base = every('day', 'days');
    case RecurrenceType.weekly:
      final days = _weekdaysFor(task);
      if (days.isEmpty) {
        base = every('week', 'weeks');
      } else {
        final names = days.map((d) => _weekdayShort[d.clamp(0, 6)]).join(', ');
        base = interval <= 1
            ? 'Every week on $names'
            : 'Every $interval weeks on $names';
      }
    case RecurrenceType.monthly:
      final day = task.recurrenceMonthDay;
      if (day == null || day == 0) {
        base = every('month', 'months');
      } else if (day == -1) {
        base = interval <= 1
            ? 'Every month on the last day'
            : 'Every $interval months on the last day';
      } else {
        final ordinal = _ordinal(day);
        base = interval <= 1
            ? 'Every month on the $ordinal'
            : 'Every $interval months on the $ordinal';
      }
    case RecurrenceType.monthlyLastDay:
      base = interval <= 1
          ? 'Every month on the last day'
          : 'Every $interval months on the last day';
    case RecurrenceType.monthlyWeekday:
      final week = task.recurrenceWeekOfMonth ?? 1;
      final weekday = task.recurrenceWeekday ??
          (task.recurrenceWeekdays.isNotEmpty
              ? task.recurrenceWeekdays.first
              : 1);
      final weekLabel = week == -1 ? 'last' : _ordinal(week);
      final dayName = _weekdayLong[weekday.clamp(0, 6)];
      base = interval <= 1
          ? 'Every month on the $weekLabel $dayName'
          : 'Every $interval months on the $weekLabel $dayName';
    default:
      base = 'Repeats';
  }

  if (task.completionBased) return '$base from completion';
  return base;
}

/// Compact subtitle label for non-default workflow status (not Not started/Done).
String? workflowStatusLabel(TududiTask task) {
  switch (task.status) {
    case TaskStatus.inProgress:
    case TaskStatus.waiting:
    case TaskStatus.planned:
    case TaskStatus.archived:
    case TaskStatus.cancelled:
      return TaskStatus.label(task.status);
    default:
      return null;
  }
}

/// Friendly due date for toasts, e.g. `Tue, Nov 11`.
String? formatFriendlyDue(String? dueDate) {
  if (dueDate == null || dueDate.isEmpty) return null;
  final parsed = DateTime.tryParse(dueDate);
  if (parsed == null) return dueDate;
  return DateFormat('EEE, MMM d').format(parsed);
}

/// Snackbar copy after a complete/uncomplete mutation.
String snackMessageForTaskComplete({
  required bool requestedDone,
  required TududiTask after,
  String? offlineQueued,
}) {
  if (offlineQueued != null) return offlineQueued;
  if (requestedDone && !after.isDone) {
    final next = formatFriendlyDue(after.dueDate);
    if (next != null) return 'Completed — next due $next';
    return 'Completed — next occurrence scheduled';
  }
  if (requestedDone) return 'Completed';
  return 'Marked incomplete';
}

/// Status icons shown next to the priority dot (repeat, overdue, workflow).
List<IconData> taskStatusIcons(TududiTask task, [DateTime? now]) {
  final icons = <IconData>[];
  if (task.isRecurring) icons.add(Symbols.repeat);
  if (isTaskOverdue(task, now)) icons.add(Symbols.warning_amber);
  switch (task.status) {
    case TaskStatus.inProgress:
      icons.add(Symbols.pending);
    case TaskStatus.waiting:
      icons.add(Symbols.hourglass);
    case TaskStatus.planned:
      icons.add(Symbols.event_upcoming);
  }
  return icons;
}

List<int> _weekdaysFor(TududiTask task) {
  if (task.recurrenceWeekdays.isNotEmpty) {
    return [...task.recurrenceWeekdays]..sort();
  }
  if (task.recurrenceWeekday != null) return [task.recurrenceWeekday!];
  return const [];
}

String _ordinal(int n) {
  final abs = n.abs();
  final mod100 = abs % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${n}th';
  return switch (abs % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}
