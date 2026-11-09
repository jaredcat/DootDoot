import 'package:equatable/equatable.dart';

import 'tag.dart';

/// Tududi task status codes (see server docs).
abstract final class TaskStatus {
  static const notStarted = 0;
  static const inProgress = 1;
  static const done = 2;
  static const archived = 3;
  static const waiting = 4;
  static const cancelled = 5;
  static const planned = 6;

  static String label(int status) {
    switch (status) {
      case inProgress:
        return 'In progress';
      case done:
        return 'Done';
      case archived:
        return 'Archived';
      case waiting:
        return 'Waiting';
      case cancelled:
        return 'Cancelled';
      case planned:
        return 'Planned';
      case notStarted:
      default:
        return 'Not started';
    }
  }

  static bool isOpen(int status) =>
      status != done && status != archived && status != cancelled;
}

/// Tududi recurrence_type values.
abstract final class RecurrenceType {
  static const none = 'none';
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const monthly = 'monthly';
  static const monthlyWeekday = 'monthly_weekday';
  static const monthlyLastDay = 'monthly_last_day';

  static bool isActive(String? type) =>
      type != null && type.isNotEmpty && type != none;
}

class TududiTask extends Equatable {
  const TududiTask({
    required this.id,
    required this.name,
    this.uid,
    this.note,
    this.status = TaskStatus.notStarted,
    this.priority,
    this.dueDate,
    this.dueTime,
    this.projectId,
    this.projectUid,
    this.projectName,
    this.areaId,
    this.areaUid,
    this.goalUid,
    this.tags = const [],
    this.subtasks = const [],
    this.completedAt,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceWeekday,
    this.recurrenceWeekdays = const [],
    this.recurrenceMonthDay,
    this.recurrenceWeekOfMonth,
    this.recurrenceEndDate,
    this.completionBased = false,
    this.originalName,
    this.todayMoveCount = 0,
  });

  final int id;
  final String name;
  final String? uid;
  final String? note;
  final int status;
  final String? priority;
  final String? dueDate;
  final String? dueTime;
  final int? projectId;
  final String? projectUid;
  final String? projectName;
  final int? areaId;
  final String? areaUid;
  final String? goalUid;
  final List<TududiTag> tags;
  final List<TududiTask> subtasks;
  final String? completedAt;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final int? recurrenceWeekday;
  final List<int> recurrenceWeekdays;
  final int? recurrenceMonthDay;
  final int? recurrenceWeekOfMonth;
  final String? recurrenceEndDate;
  final bool completionBased;
  final String? originalName;
  final int todayMoveCount;

  bool get isDone => status == TaskStatus.done;
  bool get isOpen => TaskStatus.isOpen(status);
  bool get isRecurring => RecurrenceType.isActive(recurrenceType);
  String get displayName =>
      originalName?.isNotEmpty == true ? originalName! : name;

  TududiTask copyWith({
    int? id,
    String? name,
    String? uid,
    String? note,
    int? status,
    String? priority,
    String? dueDate,
    String? dueTime,
    int? projectId,
    String? projectUid,
    String? projectName,
    int? areaId,
    String? areaUid,
    String? goalUid,
    List<TududiTag>? tags,
    List<TududiTask>? subtasks,
    String? completedAt,
    String? recurrenceType,
    int? recurrenceInterval,
    int? recurrenceWeekday,
    List<int>? recurrenceWeekdays,
    int? recurrenceMonthDay,
    int? recurrenceWeekOfMonth,
    String? recurrenceEndDate,
    bool? completionBased,
    String? originalName,
    int? todayMoveCount,
    bool clearRecurrence = false,
  }) {
    return TududiTask(
      id: id ?? this.id,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      note: note ?? this.note,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      projectId: projectId ?? this.projectId,
      projectUid: projectUid ?? this.projectUid,
      projectName: projectName ?? this.projectName,
      areaId: areaId ?? this.areaId,
      areaUid: areaUid ?? this.areaUid,
      goalUid: goalUid ?? this.goalUid,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      completedAt: completedAt ?? this.completedAt,
      recurrenceType:
          clearRecurrence ? null : (recurrenceType ?? this.recurrenceType),
      recurrenceInterval: clearRecurrence
          ? null
          : (recurrenceInterval ?? this.recurrenceInterval),
      recurrenceWeekday: clearRecurrence
          ? null
          : (recurrenceWeekday ?? this.recurrenceWeekday),
      recurrenceWeekdays: clearRecurrence
          ? const []
          : (recurrenceWeekdays ?? this.recurrenceWeekdays),
      recurrenceMonthDay: clearRecurrence
          ? null
          : (recurrenceMonthDay ?? this.recurrenceMonthDay),
      recurrenceWeekOfMonth: clearRecurrence
          ? null
          : (recurrenceWeekOfMonth ?? this.recurrenceWeekOfMonth),
      recurrenceEndDate: clearRecurrence
          ? null
          : (recurrenceEndDate ?? this.recurrenceEndDate),
      completionBased:
          clearRecurrence ? false : (completionBased ?? this.completionBased),
      originalName: originalName ?? this.originalName,
      todayMoveCount: todayMoveCount ?? this.todayMoveCount,
    );
  }

  factory TududiTask.fromJson(Map<String, dynamic> json) {
    final project = json['Project'] is Map
        ? Map<String, dynamic>.from(json['Project'] as Map)
        : null;
    final tagsJson = json['tags'] ?? json['Tags'];
    final subtasksJson = json['subtasks'] ?? json['Subtasks'];

    return TududiTask(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
      note: json['note']?.toString() ?? json['description']?.toString(),
      status: _asInt(json['status']),
      priority: json['priority']?.toString(),
      dueDate: json['due_date']?.toString(),
      dueTime: json['due_time']?.toString(),
      projectId: _asIntOrNull(json['project_id']),
      projectUid: json['project_uid']?.toString() ?? project?['uid']?.toString(),
      projectName: project?['name']?.toString(),
      areaId: _asIntOrNull(json['area_id']),
      areaUid: json['area_uid']?.toString(),
      goalUid: json['goal_uid']?.toString(),
      tags: _parseTags(tagsJson),
      subtasks: _parseTasks(subtasksJson),
      completedAt: json['completed_at']?.toString(),
      recurrenceType: json['recurrence_type']?.toString(),
      recurrenceInterval: _asIntOrNull(json['recurrence_interval']),
      recurrenceWeekday: _asIntOrNull(json['recurrence_weekday']),
      recurrenceWeekdays: _parseIntList(json['recurrence_weekdays']),
      recurrenceMonthDay: _asIntOrNull(json['recurrence_month_day']),
      recurrenceWeekOfMonth: _asIntOrNull(json['recurrence_week_of_month']),
      recurrenceEndDate: json['recurrence_end_date']?.toString(),
      completionBased: _asBool(json['completion_based']),
      originalName: json['original_name']?.toString(),
      todayMoveCount: _asInt(json['today_move_count']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        // Prefer the user-visible title; tududi often keeps that in original_name.
        'name': displayName,
        if (note != null && note!.isNotEmpty) 'note': note,
        'status': status,
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'due_date': dueDate,
        if (dueTime != null) 'due_time': dueTime,
        if (projectId != null) 'project_id': projectId,
        if (projectUid != null) 'project_uid': projectUid,
        if (areaId != null) 'area_id': areaId,
        if (areaUid != null) 'area_uid': areaUid,
        if (tags.isNotEmpty) 'tags': tags.map((t) => t.name).toList(),
        ...recurrenceToJson(),
      };

  Map<String, dynamic> toPatchJson() => {
        // Prefer the user-visible title; tududi often keeps that in original_name.
        'name': displayName,
        if (note != null) 'note': note,
        'status': status,
        if (priority != null) 'priority': priority,
        'due_date': dueDate,
        'due_time': dueTime,
        if (projectId != null) 'project_id': projectId,
        if (projectUid != null) 'project_uid': projectUid,
        if (areaId != null) 'area_id': areaId,
        if (areaUid != null) 'area_uid': areaUid,
        if (tags.isNotEmpty) 'tags': tags.map((t) => t.name).toList(),
        ...recurrenceToJson(),
      };

  /// JSON fragment for create/patch of recurrence fields.
  Map<String, dynamic> recurrenceToJson() {
    if (!isRecurring) {
      return {'recurrence_type': RecurrenceType.none};
    }
    return {
      'recurrence_type': recurrenceType,
      'recurrence_interval': recurrenceInterval ?? 1,
      if (recurrenceWeekday != null) 'recurrence_weekday': recurrenceWeekday,
      if (recurrenceWeekdays.isNotEmpty)
        'recurrence_weekdays': recurrenceWeekdays,
      if (recurrenceMonthDay != null) 'recurrence_month_day': recurrenceMonthDay,
      if (recurrenceWeekOfMonth != null)
        'recurrence_week_of_month': recurrenceWeekOfMonth,
      if (recurrenceEndDate != null && recurrenceEndDate!.isNotEmpty)
        'recurrence_end_date': recurrenceEndDate,
      'completion_based': completionBased,
    };
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        name,
        status,
        dueDate,
        projectId,
        recurrenceType,
        recurrenceInterval,
      ];
}

List<TududiTag> _parseTags(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => TududiTag.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<TududiTask> _parseTasks(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => TududiTask.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

List<int> _parseIntList(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is int)
        item
      else if (item is num)
        item.toInt()
      else
        ...[
          if (int.tryParse(item.toString()) != null) int.parse(item.toString()),
        ],
  ];
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value?.toString().toLowerCase();
  return s == 'true' || s == '1';
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
