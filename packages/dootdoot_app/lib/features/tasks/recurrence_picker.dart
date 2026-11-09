import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tududi_api/tududi_api.dart';

import 'task_actions.dart';
import 'task_status_display.dart';

class RecurrenceDraft {
  const RecurrenceDraft({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.weekdays = const [],
    this.monthDay = 1,
    this.weekOfMonth = 1,
    this.weekday = 1,
    this.endDate,
    this.completionBased = false,
  });

  factory RecurrenceDraft.fromTask(TududiTask task) {
    final type = RecurrenceType.isActive(task.recurrenceType)
        ? task.recurrenceType!
        : RecurrenceType.none;
    final weekdays = task.recurrenceWeekdays.isNotEmpty
        ? List<int>.from(task.recurrenceWeekdays)
        : (task.recurrenceWeekday != null
            ? [task.recurrenceWeekday!]
            : <int>[]);
    return RecurrenceDraft(
      type: type,
      interval: task.recurrenceInterval ?? 1,
      weekdays: weekdays,
      monthDay: _defaultMonthDay(task),
      weekOfMonth: task.recurrenceWeekOfMonth ?? 1,
      weekday: task.recurrenceWeekday ??
          (weekdays.isNotEmpty ? weekdays.first : DateTime.now().weekday % 7),
      endDate: task.recurrenceEndDate,
      completionBased: task.completionBased,
    );
  }

  final String type;
  final int interval;
  final List<int> weekdays;

  /// Calendar day of month (1–31) for non-completion monthly repeats.
  final int monthDay;
  final int weekOfMonth;
  final int weekday;
  final String? endDate;
  final bool completionBased;

  bool get isActive => RecurrenceType.isActive(type);

  RecurrenceDraft copyWith({
    String? type,
    int? interval,
    List<int>? weekdays,
    int? monthDay,
    int? weekOfMonth,
    int? weekday,
    String? endDate,
    bool? completionBased,
    bool clearEndDate = false,
  }) {
    return RecurrenceDraft(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      monthDay: monthDay ?? this.monthDay,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      weekday: weekday ?? this.weekday,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      completionBased: completionBased ?? this.completionBased,
    );
  }

  /// Body fragment suitable for `patchTaskFields`.
  Map<String, dynamic> toPatchBody() {
    if (!isActive) {
      return {
        'recurrence_type': RecurrenceType.none,
        'recurrence_interval': null,
        'recurrence_weekday': null,
        'recurrence_weekdays': null,
        'recurrence_month_day': null,
        'recurrence_week_of_month': null,
        'recurrence_end_date': null,
        'completion_based': false,
      };
    }

    final body = <String, dynamic>{
      'recurrence_type': type,
      'recurrence_interval': interval < 1 ? 1 : interval,
      'completion_based': completionBased,
      'recurrence_end_date':
          endDate != null && endDate!.isNotEmpty ? endDate : null,
    };

    switch (type) {
      case RecurrenceType.weekly:
        final days = [...weekdays]..sort();
        body['recurrence_weekdays'] = days.isEmpty ? [weekday] : days;
        body['recurrence_weekday'] = days.isEmpty ? weekday : days.first;
        body['recurrence_month_day'] = null;
        body['recurrence_week_of_month'] = null;
      case RecurrenceType.monthly:
        // Completion-based: omit fixed day so tududi keeps the finish day.
        // Otherwise always send a concrete day (1–31).
        body['recurrence_month_day'] =
            completionBased ? null : monthDay.clamp(1, 31);
        body['recurrence_weekday'] = null;
        body['recurrence_weekdays'] = null;
        body['recurrence_week_of_month'] = null;
      case RecurrenceType.monthlyWeekday:
        body['recurrence_weekday'] = weekday;
        body['recurrence_week_of_month'] = weekOfMonth;
        body['recurrence_weekdays'] = null;
        body['recurrence_month_day'] = null;
      case RecurrenceType.monthlyLastDay:
        body['recurrence_month_day'] = -1;
        body['recurrence_weekday'] = null;
        body['recurrence_weekdays'] = null;
        body['recurrence_week_of_month'] = null;
      default:
        body['recurrence_weekday'] = null;
        body['recurrence_weekdays'] = null;
        body['recurrence_month_day'] = null;
        body['recurrence_week_of_month'] = null;
    }
    return body;
  }

  /// Preview label using a synthetic task.
  String get previewLabel {
    final task = TududiTask(
      id: 0,
      name: '',
      recurrenceType: isActive ? type : null,
      recurrenceInterval: interval,
      recurrenceWeekday: weekday,
      recurrenceWeekdays: weekdays,
      recurrenceMonthDay:
          type == RecurrenceType.monthly && completionBased ? null : monthDay,
      recurrenceWeekOfMonth: weekOfMonth,
      recurrenceEndDate: endDate,
      completionBased: completionBased,
    );
    return recurrenceLabel(task) ?? 'Does not repeat';
  }
}

/// Prefer stored month day, else due date’s day, else today.
int _defaultMonthDay(TududiTask task) {
  final raw = task.recurrenceMonthDay;
  if (raw != null && raw > 0) return raw.clamp(1, 31);
  final due = DateTime.tryParse(task.dueDate ?? '');
  if (due != null) return due.day;
  return DateTime.now().day.clamp(1, 31);
}

/// Opens a recurrence editor. Returns a draft on Save, null if dismissed.
Future<RecurrenceDraft?> showRecurrencePicker(
  BuildContext context, {
  required TududiTask task,
}) {
  return showModalBottomSheet<RecurrenceDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _RecurrencePickerSheet(
        initial: RecurrenceDraft.fromTask(task),
      );
    },
  );
}

class _RecurrencePickerSheet extends StatefulWidget {
  const _RecurrencePickerSheet({required this.initial});

  final RecurrenceDraft initial;

  @override
  State<_RecurrencePickerSheet> createState() => _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState extends State<_RecurrencePickerSheet> {
  static const _patterns = <(String, String)>[
    (RecurrenceType.none, 'Does not repeat'),
    (RecurrenceType.daily, 'Daily'),
    (RecurrenceType.weekly, 'Weekly'),
    (RecurrenceType.monthly, 'Monthly'),
    (RecurrenceType.monthlyWeekday, 'Monthly on weekday'),
    (RecurrenceType.monthlyLastDay, 'Last day of month'),
  ];

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _weekOfMonthChoices = <(int, String)>[
    (1, '1st'),
    (2, '2nd'),
    (3, '3rd'),
    (4, '4th'),
    (5, '5th'),
    (-1, 'Last'),
  ];

  late RecurrenceDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Repeat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _draft.previewLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _draft.type,
                onChanged: (next) {
                  if (next == null) return;
                  setState(() => _draft = _draft.copyWith(type: next));
                },
                child: Column(
                  children: [
                    for (final (value, label) in _patterns)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(label),
                        value: value,
                      ),
                  ],
                ),
              ),
              if (_draft.isActive) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Every'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _draft.interval <= 1
                            ? null
                            : () => setState(
                                  () => _draft = _draft.copyWith(
                                    interval: _draft.interval - 1,
                                  ),
                                ),
                        icon: const Icon(Symbols.remove),
                      ),
                      Text(
                        '${_draft.interval}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _draft = _draft.copyWith(
                            interval: _draft.interval + 1,
                          ),
                        ),
                        icon: const Icon(Symbols.add),
                      ),
                      Text(_intervalUnitLabel(_draft.type, _draft.interval)),
                    ],
                  ),
                ),
                if (_draft.type == RecurrenceType.weekly) ...[
                  const SizedBox(height: 4),
                  Text(
                    'On days',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < 7; i++)
                        FilterChip(
                          label: Text(_weekdayLabels[i]),
                          selected: _draft.weekdays.contains(i),
                          onSelected: (selected) {
                            final next = [..._draft.weekdays];
                            if (selected) {
                              next.add(i);
                            } else {
                              next.remove(i);
                            }
                            setState(
                              () => _draft = _draft.copyWith(weekdays: next),
                            );
                          },
                        ),
                    ],
                  ),
                ],
                // Calendar monthly only. Hidden when completion-based (finish
                // day becomes the anchor instead of a fixed calendar day).
                if (_draft.type == RecurrenceType.monthly &&
                    !_draft.completionBased) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Day of month'),
                    trailing: DropdownButton<int>(
                      value: _draft.monthDay.clamp(1, 31),
                      items: [
                        for (var d = 1; d <= 31; d++)
                          DropdownMenuItem(value: d, child: Text('$d')),
                      ],
                      onChanged: (d) {
                        if (d == null) return;
                        setState(
                          () => _draft = _draft.copyWith(monthDay: d),
                        );
                      },
                    ),
                  ),
                ],
                if (_draft.type == RecurrenceType.monthlyWeekday) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Week'),
                    trailing: DropdownButton<int>(
                      value: _draft.weekOfMonth,
                      items: [
                        for (final (value, label) in _weekOfMonthChoices)
                          DropdownMenuItem(value: value, child: Text(label)),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(
                          () => _draft = _draft.copyWith(weekOfMonth: v),
                        );
                      },
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Weekday'),
                    trailing: DropdownButton<int>(
                      value: _draft.weekday.clamp(0, 6),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Sunday')),
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 2, child: Text('Tuesday')),
                        DropdownMenuItem(value: 3, child: Text('Wednesday')),
                        DropdownMenuItem(value: 4, child: Text('Thursday')),
                        DropdownMenuItem(value: 5, child: Text('Friday')),
                        DropdownMenuItem(value: 6, child: Text('Saturday')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(
                          () => _draft = _draft.copyWith(weekday: v),
                        );
                      },
                    ),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Based on completion'),
                  subtitle: Text(
                    _draft.completionBased
                        ? (_draft.type == RecurrenceType.monthly
                            ? 'Next due is one month after the day you finish'
                            : 'Count from the day you finish, then apply the pattern')
                        : 'Count from the current due date, even if you finish late',
                  ),
                  value: _draft.completionBased,
                  onChanged: (v) => setState(
                    () => _draft = _draft.copyWith(completionBased: v),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End date'),
                  subtitle: Text(
                    _draft.endDate == null || _draft.endDate!.isEmpty
                        ? 'Never'
                        : _draft.endDate!,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_draft.endDate != null && _draft.endDate!.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear end date',
                          onPressed: () => setState(
                            () => _draft = _draft.copyWith(clearEndDate: true),
                          ),
                          icon: const Icon(Symbols.close),
                        ),
                      const Icon(Symbols.chevron_right),
                    ],
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = DateTime.tryParse(_draft.endDate ?? '') ??
                        now.add(const Duration(days: 30));
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial.isBefore(now) ? now : initial,
                      firstDate: now,
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked == null) return;
                    setState(
                      () => _draft = _draft.copyWith(
                        endDate: formatDateYmd(picked),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_draft),
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _intervalUnitLabel(String type, int interval) {
    final plural = interval == 1;
    return switch (type) {
      RecurrenceType.daily => plural ? ' day' : ' days',
      RecurrenceType.weekly => plural ? ' week' : ' weeks',
      RecurrenceType.monthly ||
      RecurrenceType.monthlyWeekday ||
      RecurrenceType.monthlyLastDay =>
        plural ? ' month' : ' months',
      _ => '',
    };
  }

}
