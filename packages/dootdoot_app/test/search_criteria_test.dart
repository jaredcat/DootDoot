import 'package:dootdoot_app/features/search/search_criteria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tududi_api/tududi_api.dart';

void main() {
  group('filterSearchResult', () {
    test('filters by entity type and query', () {
      final raw = {
        'tasks': [
          {'uid': 't1', 'name': 'Buy milk'},
          {'uid': 't2', 'name': 'Call bank'},
        ],
        'projects': [
          {'uid': 'p1', 'name': 'Home'},
        ],
        'notes': [
          {'uid': 'n1', 'title': 'Milk ideas'},
        ],
      };
      final filtered = filterSearchResult(
        raw,
        const SearchCriteria(
          query: 'milk',
          includeTasks: true,
          includeProjects: false,
          includeNotes: true,
        ),
      );
      expect((filtered['tasks'] as List).length, 1);
      expect((filtered['projects'] as List), isEmpty);
      expect((filtered['notes'] as List).length, 1);
    });
  });

  group('offlineSearchResult', () {
    test('matches tasks notes projects from cache', () {
      final result = offlineSearchResult(
        criteria: const SearchCriteria(query: 'alpha'),
        tasks: [
          const TududiTask(id: 1, name: 'Alpha task', uid: 't1'),
          const TududiTask(id: 2, name: 'Beta', uid: 't2'),
        ],
        projects: [
          const TududiProject(id: 1, name: 'Alpha project', uid: 'p1'),
        ],
        notes: [const TududiNote(id: 1, title: 'Alpha note', uid: 'n1')],
      );
      expect((result['tasks'] as List).single['name'], 'Alpha task');
      expect((result['projects'] as List).single['name'], 'Alpha project');
      expect((result['notes'] as List).single['title'], 'Alpha note');
      expect(result['offline'], isTrue);
    });
  });

  group('SearchCriteria.fromView', () {
    test('maps filters', () {
      const view = TududiView(
        id: 1,
        name: 'Work',
        searchQuery: 'focus',
        filters: ['Tasks', 'Notes'],
        priority: 'high',
        tags: ['work'],
      );
      final c = SearchCriteria.fromView(view);
      expect(c.query, 'focus');
      expect(c.includeTasks, isTrue);
      expect(c.includeNotes, isTrue);
      expect(c.includeProjects, isFalse);
      expect(c.priority, 'high');
      expect(c.tag, 'work');
    });
  });
}
