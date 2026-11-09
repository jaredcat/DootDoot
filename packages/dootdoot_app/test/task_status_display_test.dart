import 'package:dootdoot_app/features/tasks/task_status_display.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tududi_api/tududi_api.dart';

TududiTask task({
  String? recurrenceType,
  int? recurrenceInterval,
  int? recurrenceWeekday,
  List<int> recurrenceWeekdays = const [],
  int? recurrenceMonthDay,
  int? recurrenceWeekOfMonth,
  bool completionBased = false,
  String? dueDate,
  int status = TaskStatus.notStarted,
}) {
  return TududiTask(
    id: 1,
    name: 'Task',
    status: status,
    dueDate: dueDate,
    recurrenceType: recurrenceType,
    recurrenceInterval: recurrenceInterval,
    recurrenceWeekday: recurrenceWeekday,
    recurrenceWeekdays: recurrenceWeekdays,
    recurrenceMonthDay: recurrenceMonthDay,
    recurrenceWeekOfMonth: recurrenceWeekOfMonth,
    completionBased: completionBased,
  );
}

void main() {
  group('recurrenceLabel', () {
    test('returns null when not recurring', () {
      expect(recurrenceLabel(task()), isNull);
      expect(recurrenceLabel(task(recurrenceType: RecurrenceType.none)), isNull);
    });

    test('formats daily', () {
      expect(
        recurrenceLabel(task(recurrenceType: RecurrenceType.daily)),
        'Every day',
      );
      expect(
        recurrenceLabel(
          task(recurrenceType: RecurrenceType.daily, recurrenceInterval: 3),
        ),
        'Every 3 days',
      );
    });

    test('formats weekly with weekdays', () {
      expect(
        recurrenceLabel(
          task(
            recurrenceType: RecurrenceType.weekly,
            recurrenceWeekdays: const [1, 3],
          ),
        ),
        'Every week on Mon, Wed',
      );
      expect(
        recurrenceLabel(
          task(
            recurrenceType: RecurrenceType.weekly,
            recurrenceInterval: 2,
            recurrenceWeekday: 2,
          ),
        ),
        'Every 2 weeks on Tue',
      );
    });

    test('formats monthly variants', () {
      expect(
        recurrenceLabel(
          task(
            recurrenceType: RecurrenceType.monthly,
            recurrenceMonthDay: 15,
          ),
        ),
        'Every month on the 15th',
      );
      expect(
        recurrenceLabel(task(recurrenceType: RecurrenceType.monthlyLastDay)),
        'Every month on the last day',
      );
      expect(
        recurrenceLabel(
          task(
            recurrenceType: RecurrenceType.monthlyWeekday,
            recurrenceWeekOfMonth: 2,
            recurrenceWeekday: 4,
          ),
        ),
        'Every month on the 2nd Thursday',
      );
    });

    test('notes completion-based scheduling', () {
      expect(
        recurrenceLabel(
          task(
            recurrenceType: RecurrenceType.monthly,
            completionBased: true,
          ),
        ),
        'Every month from completion',
      );
      expect(
        recurrenceLabel(
          task(
            recurrenceType: RecurrenceType.monthly,
            recurrenceMonthDay: 1,
            completionBased: true,
          ),
        ),
        'Every month on the 1st from completion',
      );
    });
  });

  group('isTaskOverdue', () {
    test('true when open and due before today', () {
      expect(
        isTaskOverdue(
          task(dueDate: '2020-01-01'),
          DateTime(2026, 11, 8),
        ),
        isTrue,
      );
    });

    test('false when done or due today/future', () {
      expect(
        isTaskOverdue(
          task(dueDate: '2020-01-01', status: TaskStatus.done),
          DateTime(2026, 11, 8),
        ),
        isFalse,
      );
      expect(
        isTaskOverdue(
          task(dueDate: '2026-11-08'),
          DateTime(2026, 11, 8),
        ),
        isFalse,
      );
    });
  });

  group('snackMessageForTaskComplete', () {
    test('announces next due for recurring advance', () {
      expect(
        snackMessageForTaskComplete(
          requestedDone: true,
          after: task(dueDate: '2026-11-11'),
        ),
        'Completed — next due Wed, Nov 11',
      );
    });

    test('completed and incomplete', () {
      expect(
        snackMessageForTaskComplete(
          requestedDone: true,
          after: task(status: TaskStatus.done),
        ),
        'Completed',
      );
      expect(
        snackMessageForTaskComplete(
          requestedDone: false,
          after: task(),
        ),
        'Marked incomplete',
      );
    });

    test('offline queued wins', () {
      expect(
        snackMessageForTaskComplete(
          requestedDone: true,
          after: task(dueDate: '2026-11-11'),
          offlineQueued: 'Saved offline — will sync when online',
        ),
        'Saved offline — will sync when online',
      );
    });
  });
}
