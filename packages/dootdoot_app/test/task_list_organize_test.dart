import 'package:dootdoot_app/features/tasks/task_list_organize.dart';
import 'package:dootdoot_app/features/tasks/today_section_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tududi_api/tududi_api.dart';

TududiTask task({
  required int id,
  required String name,
  int status = TaskStatus.notStarted,
  String? dueDate,
  String? priority,
  String? projectName,
  String? completedAt,
  String? recurrenceType,
  List<TududiTag> tags = const [],
}) {
  return TududiTask(
    id: id,
    name: name,
    uid: 'u$id',
    status: status,
    dueDate: dueDate,
    priority: priority,
    projectName: projectName,
    completedAt: completedAt,
    recurrenceType: recurrenceType,
    tags: tags,
  );
}

void main() {
  final now = DateTime(2026, 11, 8);

  group('organizeTodaySections', () {
    test('partitions without duplication and sorts by priority', () {
      final sections = organizeTodaySections([
        task(
          id: 1,
          name: 'Low overdue',
          dueDate: '2026-11-01',
          priority: 'low',
        ),
        task(
          id: 2,
          name: 'High overdue',
          dueDate: '2026-11-02',
          priority: 'high',
        ),
        task(
          id: 3,
          name: 'In progress',
          status: TaskStatus.inProgress,
          dueDate: '2026-11-01',
        ),
        task(id: 4, name: 'Suggestion', dueDate: '2026-11-08'),
        task(
          id: 5,
          name: 'Done',
          status: TaskStatus.done,
          completedAt: '2026-11-08T12:00:00Z',
        ),
      ], now: now);

      expect(sections.map((s) => s.title).toList(), [
        'Overdue',
        'Due today',
        'Planned',
        'Completed',
      ]);
      expect(sections[0].tasks.map((t) => t.name), [
        'High overdue',
        'Low overdue',
      ]);
      expect(sections[1].tasks.single.name, 'Suggestion');
      expect(sections[2].tasks.single.name, 'In progress');
      expect(sections[3].tasks.single.name, 'Done');
    });

    test('respects section visibility (planned always kept)', () {
      final sections = organizeTodaySections(
        [
          task(id: 1, name: 'Overdue', dueDate: '2026-11-01'),
          task(id: 2, name: 'In progress', status: TaskStatus.inProgress),
          task(id: 3, name: 'Due today', dueDate: '2026-11-08'),
          task(id: 4, name: 'Done', status: TaskStatus.done),
        ],
        now: now,
        visibility: const TodaySectionVisibility(
          showOverdue: false,
          showSuggested: false,
          showCompleted: false,
        ),
      );

      expect(sections.map((s) => s.title).toList(), ['Planned']);
      expect(sections.single.tasks.single.name, 'In progress');
    });

    test('hides due today when Overdue/Due today toggle is off', () {
      final sections = organizeTodaySections(
        [
          task(id: 1, name: 'Due today', dueDate: '2026-11-08'),
          task(id: 2, name: 'Undated suggestion'),
        ],
        now: now,
        visibility: const TodaySectionVisibility(
          showOverdue: false,
          showSuggested: true,
        ),
      );

      expect(sections.map((s) => s.title).toList(), ['Suggested']);
      expect(sections.single.tasks.single.name, 'Undated suggestion');
    });

    test('skips deferred and subtasks; today tag lands in Due today', () {
      final sections = organizeTodaySections(
        [
          task(
            id: 1,
            name: 'Pinned',
            tags: [const TududiTag(id: 1, name: 'today')],
          ),
          TududiTask(
            id: 2,
            name: 'Deferred',
            dueDate: '2026-11-08',
            deferUntil: '2099-01-01T09:00:00',
          ),
          TududiTask(
            id: 3,
            name: 'Child',
            parentTaskId: 1,
            dueDate: '2026-11-08',
          ),
        ],
        now: now,
        visibility: const TodaySectionVisibility(showSuggested: true),
      );

      expect(sections.single.title, 'Due today');
      expect(sections.single.tasks.single.name, 'Pinned');
    });
  });

  group('isTodayCandidate / filterTodayCandidates', () {
    test('keeps not-started recurring parent due today', () {
      final dueToday = task(
        id: 1,
        name: 'Daily chore',
        dueDate: '2026-11-08',
        recurrenceType: RecurrenceType.daily,
      );
      expect(isTodayCandidate(dueToday, now: now), isTrue);
      expect(
        filterTodayCandidates([dueToday], now: now).single.name,
        'Daily chore',
      );
    });

    test('keeps overdue and planned; drops future and undated open', () {
      final tasks = [
        task(id: 1, name: 'Overdue', dueDate: '2026-11-01'),
        task(id: 2, name: 'Planned', status: TaskStatus.planned),
        task(id: 3, name: 'Tomorrow', dueDate: '2026-11-09'),
        task(id: 4, name: 'Someday'),
        task(
          id: 5,
          name: 'Done today',
          status: TaskStatus.done,
          completedAt: '2026-11-08T18:00:00',
        ),
      ];

      final kept = filterTodayCandidates(tasks, now: now).map((t) => t.name);
      expect(kept, containsAll(['Overdue', 'Planned', 'Done today']));
      expect(kept, isNot(contains('Tomorrow')));
      expect(kept, isNot(contains('Someday')));
    });
  });

  group('organizeUpcomingSections', () {
    test('groups by day and filters active', () {
      final sections = organizeUpcomingSections(
        [
          task(id: 1, name: 'Today a', dueDate: '2026-11-08', priority: 'low'),
          task(id: 2, name: 'Today b', dueDate: '2026-11-08', priority: 'high'),
          task(id: 3, name: 'Tomorrow', dueDate: '2026-11-09'),
          task(
            id: 4,
            name: 'Done today',
            dueDate: '2026-11-08',
            status: TaskStatus.done,
          ),
          task(id: 5, name: 'No date'),
        ],
        statusFilter: UpcomingStatusFilter.active,
        now: now,
      );

      expect(sections.map((s) => s.title).toList(), [
        'Today',
        'Tomorrow',
        'No due date',
      ]);
      expect(sections[0].tasks.map((t) => t.name), ['Today b', 'Today a']);
      expect(
        sections.any((s) => s.tasks.any((t) => t.name == 'Done today')),
        isFalse,
      );
    });

    test('completed filter keeps done tasks', () {
      final sections = organizeUpcomingSections(
        [
          task(
            id: 1,
            name: 'Done',
            dueDate: '2026-11-08',
            status: TaskStatus.done,
          ),
          task(id: 2, name: 'Open', dueDate: '2026-11-08'),
        ],
        statusFilter: UpcomingStatusFilter.completed,
        now: now,
      );

      expect(sections.single.tasks.single.name, 'Done');
    });

    test('name sort flattens across days', () {
      final sections = organizeUpcomingSections(
        [
          task(id: 1, name: 'Zebra', dueDate: '2026-11-08'),
          task(id: 2, name: 'Apple', dueDate: '2026-11-09'),
        ],
        statusFilter: UpcomingStatusFilter.active,
        sort: const UpcomingSort(
          field: UpcomingSortField.name,
          ascending: true,
        ),
        now: now,
      );

      expect(sections.single.title, 'Name');
      expect(sections.single.tasks.map((t) => t.name), ['Apple', 'Zebra']);
    });

    test('priority sort flattens across days', () {
      final sections = organizeUpcomingSections(
        [
          task(
            id: 1,
            name: 'Later high',
            dueDate: '2026-11-09',
            priority: 'high',
          ),
          task(
            id: 2,
            name: 'Today low',
            dueDate: '2026-11-08',
            priority: 'low',
          ),
        ],
        statusFilter: UpcomingStatusFilter.active,
        sort: const UpcomingSort(
          field: UpcomingSortField.priority,
          ascending: true,
        ),
        now: now,
      );

      expect(sections.single.title, 'Priority');
      expect(sections.single.tasks.map((t) => t.name), [
        'Later high',
        'Today low',
      ]);
    });
  });
}
