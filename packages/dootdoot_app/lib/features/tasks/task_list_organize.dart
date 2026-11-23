import 'package:intl/intl.dart';
import 'package:tududi_api/tududi_api.dart';

import 'today_section_prefs.dart';

/// Upcoming status filter (parity with Tududi Upcoming toolbar).
enum UpcomingStatusFilter { active, completed, all }

extension UpcomingStatusFilterX on UpcomingStatusFilter {
  String get label => switch (this) {
    UpcomingStatusFilter.active => 'Active',
    UpcomingStatusFilter.completed => 'Completed',
    UpcomingStatusFilter.all => 'All',
  };

  bool matches(TududiTask task) => switch (this) {
    UpcomingStatusFilter.active => task.isOpen,
    UpcomingStatusFilter.completed => task.isDone,
    UpcomingStatusFilter.all => true,
  };
}

/// Sort field for Upcoming day groups (created_at deferred until API exposes it).
enum UpcomingSortField { priority, dueDate, name }

extension UpcomingSortFieldX on UpcomingSortField {
  String get label => switch (this) {
    UpcomingSortField.priority => 'Priority',
    UpcomingSortField.dueDate => 'Due date',
    UpcomingSortField.name => 'Name',
  };
}

class UpcomingSort {
  /// Default keeps day grouping ([UpcomingSortField.dueDate]).
  const UpcomingSort({
    this.field = UpcomingSortField.dueDate,
    this.ascending = true,
  });

  final UpcomingSortField field;
  final bool ascending;

  /// Day columns only make sense when sorting by due date.
  bool get groupsByDay => field == UpcomingSortField.dueDate;

  UpcomingSort copyWith({UpcomingSortField? field, bool? ascending}) {
    return UpcomingSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Named section on the Today list (parity with Tududi Today page).
enum TodaySectionKind { overdue, dueToday, planned, suggested, completed }

extension TodaySectionKindX on TodaySectionKind {
  String get label => switch (this) {
    TodaySectionKind.overdue => 'Overdue',
    TodaySectionKind.dueToday => 'Due today',
    TodaySectionKind.planned => 'Planned',
    TodaySectionKind.suggested => 'Suggested',
    TodaySectionKind.completed => 'Completed',
  };
}

class TaskSection {
  const TaskSection({required this.title, required this.tasks, this.kind});

  final String title;
  final List<TududiTask> tasks;
  final TodaySectionKind? kind;
}

DateTime? taskDueDay(TududiTask task) {
  final raw = task.dueDate;
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime calendarDay([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

int priorityRank(TududiTask task) {
  return switch (task.priority) {
    'high' || '2' => 0,
    'medium' || '1' => 1,
    'low' || '0' => 2,
    _ => 3,
  };
}

/// Tududi-style order: priority → due date → project name.
int compareTasksTududi(TududiTask a, TududiTask b) {
  final byPriority = priorityRank(a).compareTo(priorityRank(b));
  if (byPriority != 0) return byPriority;

  final aDue = taskDueDay(a);
  final bDue = taskDueDay(b);
  if (aDue != null && bDue != null) {
    final byDue = aDue.compareTo(bDue);
    if (byDue != 0) return byDue;
  } else if (aDue != null) {
    return -1;
  } else if (bDue != null) {
    return 1;
  }

  final aProject = a.projectName ?? '';
  final bProject = b.projectName ?? '';
  final byProject = aProject.toLowerCase().compareTo(bProject.toLowerCase());
  if (byProject != 0) return byProject;

  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

int compareTasksUpcoming(TududiTask a, TududiTask b, UpcomingSort sort) {
  final int primary = switch (sort.field) {
    UpcomingSortField.priority => priorityRank(a).compareTo(priorityRank(b)),
    UpcomingSortField.dueDate => () {
      final aDue = taskDueDay(a);
      final bDue = taskDueDay(b);
      if (aDue != null && bDue != null) return aDue.compareTo(bDue);
      if (aDue != null) return -1;
      if (bDue != null) return 1;
      return 0;
    }(),
    UpcomingSortField.name => a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    ),
  };
  if (primary != 0) {
    return sort.ascending ? primary : -primary;
  }
  // Stable secondary: Tududi default chain without reversing.
  return compareTasksTududi(a, b);
}

bool _isPlannedStatus(TududiTask task) {
  return task.status == TaskStatus.inProgress ||
      task.status == TaskStatus.planned ||
      task.status == TaskStatus.waiting;
}

DateTime? _completedDay(TududiTask task) {
  final raw = task.completedAt;
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final local = parsed.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// True when [defer_until] is still in the future (task should stay hidden).
bool isDeferred(TududiTask task, {DateTime? now}) {
  final raw = task.deferUntil;
  if (raw == null || raw.isEmpty) return false;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return false;
  final when = parsed.isUtc ? parsed.toLocal() : parsed;
  return when.isAfter(now ?? DateTime.now());
}

/// Whether [task] belongs on Today (metrics-query parity, not server `type=today`).
///
/// Server `type=today` omits not-started parents that are due today/overdue;
/// Tududi web uses separate due-today/overdue fetches instead.
bool isTodayCandidate(TududiTask task, {DateTime? now}) {
  if (task.isSubtask) return false;
  final today = calendarDay(now);
  if (task.isDone ||
      task.status == TaskStatus.archived ||
      task.status == TaskStatus.cancelled) {
    final completed = _completedDay(task);
    return completed != null && completed == today;
  }
  if (isDeferred(task, now: now)) return false;
  if (_isPlannedStatus(task)) return true;
  if (task.hasTodayTag) return true;
  final due = taskDueDay(task);
  return due != null && !due.isAfter(today);
}

int _suggestedRank(TududiTask task) {
  final pri = priorityRank(task);
  final due = taskDueDay(task);
  // High undated first, then high with future due, then medium, …
  final dueBucket = due == null ? 0 : 1;
  return pri * 10 + dueBucket;
}

/// Ranked Suggested pool (Tududi-style) from open non-Today-core tasks.
List<TududiTask> rankSuggestedCandidates(
  Iterable<TududiTask> tasks, {
  DateTime? now,
  int limit = 10,
}) {
  final today = calendarDay(now);
  final pool = <TududiTask>[];
  for (final task in tasks) {
    if (task.isSubtask || !task.isOpen) continue;
    if (isDeferred(task, now: now)) continue;
    if (_isPlannedStatus(task)) continue;
    if (task.hasTodayTag) continue;
    final due = taskDueDay(task);
    if (due != null && !due.isAfter(today)) continue;
    if (task.hasSomedayTag) continue; // fill later only if needed
    pool.add(task);
  }
  pool.sort((a, b) {
    final byRank = _suggestedRank(a).compareTo(_suggestedRank(b));
    if (byRank != 0) return byRank;
    return compareTasksTududi(a, b);
  });

  if (pool.length >= limit) return pool.take(limit).toList();

  final someday = <TududiTask>[];
  for (final task in tasks) {
    if (task.isSubtask || !task.isOpen) continue;
    if (isDeferred(task, now: now)) continue;
    if (!task.hasSomedayTag) continue;
    if (_isPlannedStatus(task)) continue;
    someday.add(task);
  }
  someday.sort(compareTasksTududi);
  final combined = [...pool, ...someday];
  return combined.take(limit).toList();
}

/// Filters and dedupes tasks for the Today screen.
List<TududiTask> filterTodayCandidates(
  Iterable<TududiTask> tasks, {
  DateTime? now,
}) {
  final deduped = <String, TududiTask>{};
  for (final task in tasks) {
    if (!isTodayCandidate(task, now: now)) continue;
    deduped[task.uid ?? '${task.id}'] = task;
  }
  return deduped.values.toList();
}

/// Parents only — subtasks belong under their parent detail.
List<TududiTask> excludeSubtasks(Iterable<TududiTask> tasks) {
  return [
    for (final t in tasks)
      if (!t.isSubtask) t,
  ];
}

/// Partition Today candidates into Tududi-like sections (no duplication).
///
/// Group-by project/area is intentionally omitted here — Tududi keeps Today as
/// fixed sections; project/area filtering belongs on Search / Projects / Views.
List<TaskSection> organizeTodaySections(
  List<TududiTask> tasks, {
  DateTime? now,
  TodaySectionVisibility visibility = const TodaySectionVisibility(),
}) {
  final today = calendarDay(now);
  final overdue = <TududiTask>[];
  final dueToday = <TududiTask>[];
  final planned = <TududiTask>[];
  final suggested = <TududiTask>[];
  final completed = <TududiTask>[];

  for (final task in tasks) {
    if (task.isSubtask) continue;
    if (task.isDone ||
        task.status == TaskStatus.archived ||
        task.status == TaskStatus.cancelled) {
      completed.add(task);
      continue;
    }
    if (isDeferred(task, now: now)) continue;
    if (_isPlannedStatus(task)) {
      planned.add(task);
      continue;
    }
    final due = taskDueDay(task);
    if (due != null && due.isBefore(today)) {
      overdue.add(task);
      continue;
    }
    if (due != null && due == today) {
      dueToday.add(task);
      continue;
    }
    // Tagged today (no due) lands with due-today work.
    if (task.hasTodayTag) {
      dueToday.add(task);
      continue;
    }
    suggested.add(task);
  }

  overdue.sort(compareTasksTududi);
  dueToday.sort(compareTasksTududi);
  planned.sort(compareTasksTududi);
  suggested.sort(compareTasksTududi);
  completed.sort((a, b) {
    final aAt = a.completedAt ?? '';
    final bAt = b.completedAt ?? '';
    final byCompleted = bAt.compareTo(aAt); // newest first
    if (byCompleted != 0) return byCompleted;
    return compareTasksTududi(a, b);
  });

  return [
    if (visibility.showOverdue && overdue.isNotEmpty)
      TaskSection(
        kind: TodaySectionKind.overdue,
        title: TodaySectionKind.overdue.label,
        tasks: overdue,
      ),
    if (visibility.showOverdue && dueToday.isNotEmpty)
      TaskSection(
        kind: TodaySectionKind.dueToday,
        title: TodaySectionKind.dueToday.label,
        tasks: dueToday,
      ),
    if (planned.isNotEmpty)
      TaskSection(
        kind: TodaySectionKind.planned,
        title: TodaySectionKind.planned.label,
        tasks: planned,
      ),
    if (visibility.showSuggested && suggested.isNotEmpty)
      TaskSection(
        kind: TodaySectionKind.suggested,
        title: TodaySectionKind.suggested.label,
        tasks: suggested,
      ),
    if (visibility.showCompleted && completed.isNotEmpty)
      TaskSection(
        kind: TodaySectionKind.completed,
        title: TodaySectionKind.completed.label,
        tasks: completed,
      ),
  ];
}

String upcomingDayLabel(DateTime day, {DateTime? now}) {
  final today = calendarDay(now);
  final tomorrow = today.add(const Duration(days: 1));
  if (day == today) return 'Today';
  if (day == tomorrow) return 'Tomorrow';
  return DateFormat('EEEE, MMM d').format(day);
}

/// Organize Upcoming tasks.
///
/// Due-date sort keeps day groups (Tududi default). Name / priority sorts use a
/// flat list so the order is visible across the whole week.
///
/// No group-by project — use Projects/Search/Views for that.
List<TaskSection> organizeUpcomingSections(
  List<TududiTask> tasks, {
  required UpcomingStatusFilter statusFilter,
  UpcomingSort sort = const UpcomingSort(),
  DateTime? now,
}) {
  final filtered = tasks.where(statusFilter.matches).toList();

  if (!sort.groupsByDay) {
    final flat = List<TududiTask>.of(filtered)
      ..sort((a, b) => compareTasksUpcoming(a, b, sort));
    if (flat.isEmpty) return const [];
    return [TaskSection(title: sort.field.label, tasks: flat)];
  }

  final byDay = <DateTime, List<TududiTask>>{};
  final noDue = <TududiTask>[];

  for (final task in filtered) {
    final due = taskDueDay(task);
    if (due == null) {
      noDue.add(task);
      continue;
    }
    byDay.putIfAbsent(due, () => []).add(task);
  }

  final days = byDay.keys.toList()..sort();
  final orderedDays = sort.ascending ? days : days.reversed.toList();

  final sections = <TaskSection>[];
  for (final day in orderedDays) {
    final list = byDay[day]!..sort((a, b) => compareTasksUpcoming(a, b, sort));
    sections.add(
      TaskSection(
        title: upcomingDayLabel(day, now: now),
        tasks: list,
      ),
    );
  }
  if (noDue.isNotEmpty) {
    noDue.sort((a, b) => compareTasksUpcoming(a, b, sort));
    sections.add(TaskSection(title: 'No due date', tasks: noDue));
  }
  return sections;
}
