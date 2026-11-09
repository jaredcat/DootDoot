import 'package:dootdoot_app/features/tasks/task_list_organize.dart';
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
  );
}

void main() {
  final now = DateTime(2026, 11, 8);

  group('organizeTodaySections', () {
    test('partitions without duplication and sorts by priority', () {
      final sections = organizeTodaySections(
        [
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
        ],
        now: now,
      );

      expect(sections.map((s) => s.title).toList(), [
        'Overdue',
        'Planned',
        'Suggested',
        'Completed',
      ]);
      expect(sections[0].tasks.map((t) => t.name), [
        'High overdue',
        'Low overdue',
      ]);
      expect(sections[1].tasks.single.name, 'In progress');
      expect(sections[2].tasks.single.name, 'Suggestion');
      expect(sections[3].tasks.single.name, 'Done');
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
  });
}
