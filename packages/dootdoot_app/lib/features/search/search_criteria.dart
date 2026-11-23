import 'package:tududi_api/tududi_api.dart';

/// Shared Search / Views filter state (entity types + criteria).
class SearchCriteria {
  const SearchCriteria({
    this.query = '',
    this.includeTasks = true,
    this.includeProjects = true,
    this.includeNotes = true,
    this.priority,
    this.due,
    this.tag,
  });

  final String query;
  final bool includeTasks;
  final bool includeProjects;
  final bool includeNotes;
  final String? priority;
  final String? due;
  final String? tag;

  SearchCriteria copyWith({
    String? query,
    bool? includeTasks,
    bool? includeProjects,
    bool? includeNotes,
    String? priority,
    String? due,
    String? tag,
    bool clearPriority = false,
    bool clearDue = false,
    bool clearTag = false,
  }) {
    return SearchCriteria(
      query: query ?? this.query,
      includeTasks: includeTasks ?? this.includeTasks,
      includeProjects: includeProjects ?? this.includeProjects,
      includeNotes: includeNotes ?? this.includeNotes,
      priority: clearPriority ? null : (priority ?? this.priority),
      due: clearDue ? null : (due ?? this.due),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }

  List<String> get entityFilters {
    final out = <String>[];
    if (includeTasks) out.add('Tasks');
    if (includeNotes) out.add('Notes');
    if (includeProjects) out.add('Projects');
    return out;
  }

  Map<String, dynamic> toViewBody(String name) => {
    'name': name,
    'search_query': query.trim().isEmpty ? null : query.trim(),
    'filters': entityFilters,
    if (priority != null) 'priority': priority,
    if (due != null) 'due': due,
    'tags': tag == null || tag!.isEmpty ? <String>[] : [tag!],
    'extras': <String>[],
    'is_pinned': false,
  };

  factory SearchCriteria.fromView(TududiView view) {
    final filters = view.filters.map((f) => f.toLowerCase()).toSet();
    final includeAll = filters.isEmpty;
    return SearchCriteria(
      query: view.searchQuery ?? '',
      includeTasks: includeAll || filters.contains('tasks'),
      includeProjects: includeAll || filters.contains('projects'),
      includeNotes: includeAll || filters.contains('notes'),
      priority: view.priority,
      due: view.due,
      tag: view.tags.isEmpty ? null : view.tags.first,
    );
  }
}

bool _textMatches(String? haystack, String needle) {
  if (needle.isEmpty) return true;
  return (haystack ?? '').toLowerCase().contains(needle.toLowerCase());
}

bool _taskMapMatches(Map map, SearchCriteria c) {
  final q = c.query.trim();
  if (!_textMatches(map['name']?.toString(), q) &&
      !_textMatches(map['original_name']?.toString(), q) &&
      !_textMatches(map['note']?.toString(), q)) {
    return false;
  }
  if (c.priority != null &&
      c.priority!.isNotEmpty &&
      (map['priority']?.toString().toLowerCase() !=
          c.priority!.toLowerCase())) {
    return false;
  }
  if (c.tag != null && c.tag!.isNotEmpty) {
    final tags = map['tags'];
    final names = <String>[];
    if (tags is List) {
      for (final t in tags) {
        if (t is String) {
          names.add(t.toLowerCase());
        } else if (t is Map) {
          names.add((t['name'] ?? '').toString().toLowerCase());
        }
      }
    }
    if (!names.contains(c.tag!.toLowerCase())) return false;
  }
  if (c.due != null && c.due!.isNotEmpty) {
    if (!_dueMatches(map['due_date']?.toString(), c.due!)) return false;
  }
  return true;
}

bool _dueMatches(String? dueDate, String dueFilter) {
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  DateTime? parsed;
  if (dueDate != null && dueDate.length >= 10) {
    parsed = DateTime.tryParse(dueDate.substring(0, 10));
  }
  switch (dueFilter) {
    case 'today':
      return parsed != null &&
          parsed.year == day.year &&
          parsed.month == day.month &&
          parsed.day == day.day;
    case 'overdue':
      return parsed != null && parsed.isBefore(day);
    case 'no_due_date':
      return parsed == null;
    case 'this_week':
      if (parsed == null) return false;
      final end = day.add(const Duration(days: 7));
      return !parsed.isBefore(day) && parsed.isBefore(end);
    case 'next_week':
      if (parsed == null) return false;
      final start = day.add(const Duration(days: 7));
      final end = day.add(const Duration(days: 14));
      return !parsed.isBefore(start) && parsed.isBefore(end);
    default:
      return true;
  }
}

/// Apply entity-type and field filters to a raw `/api/search` result map.
Map<String, dynamic> filterSearchResult(
  Map<String, dynamic> raw,
  SearchCriteria criteria,
) {
  final tasks = ((raw['tasks'] as List?) ?? const [])
      .whereType<Map>()
      .where((t) => criteria.includeTasks && _taskMapMatches(t, criteria))
      .toList();
  final projects = ((raw['projects'] as List?) ?? const [])
      .whereType<Map>()
      .where((p) {
        if (!criteria.includeProjects) return false;
        final q = criteria.query.trim();
        return _textMatches(p['name']?.toString(), q) ||
            _textMatches(p['description']?.toString(), q);
      })
      .toList();
  final notes = ((raw['notes'] as List?) ?? const []).whereType<Map>().where((
    n,
  ) {
    if (!criteria.includeNotes) return false;
    final q = criteria.query.trim();
    if (!_textMatches(n['title']?.toString(), q) &&
        !_textMatches(n['content']?.toString(), q) &&
        !_textMatches(n['name']?.toString(), q)) {
      return false;
    }
    if (criteria.tag != null && criteria.tag!.isNotEmpty) {
      final tags = n['tags'];
      final names = <String>[];
      if (tags is List) {
        for (final t in tags) {
          if (t is String) {
            names.add(t.toLowerCase());
          } else if (t is Map) {
            names.add((t['name'] ?? '').toString().toLowerCase());
          }
        }
      }
      if (!names.contains(criteria.tag!.toLowerCase())) return false;
    }
    return true;
  }).toList();
  return {
    'tasks': tasks,
    'projects': projects,
    'notes': notes,
    if (raw['offline'] == true) 'offline': true,
  };
}

/// Build a search-shaped result from local caches (Pro offline / failed search).
Map<String, dynamic> offlineSearchResult({
  required SearchCriteria criteria,
  required List<TududiTask> tasks,
  required List<TududiProject> projects,
  required List<TududiNote> notes,
}) {
  final q = criteria.query.trim().toLowerCase();
  final taskMaps = <Map<String, dynamic>>[];
  if (criteria.includeTasks) {
    for (final t in tasks) {
      if (t.isSubtask) continue;
      final map = {
        'uid': t.uid,
        'name': t.displayName,
        'note': t.note,
        'priority': t.priority,
        'due_date': t.dueDate,
        'tags': t.tags.map((tag) => tag.toJson()).toList(),
      };
      if (_taskMapMatches(map, criteria)) taskMaps.add(map);
    }
  }
  final projectMaps = <Map<String, dynamic>>[];
  if (criteria.includeProjects) {
    for (final p in projects) {
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !(p.description ?? '').toLowerCase().contains(q)) {
        continue;
      }
      projectMaps.add({'uid': p.uid, 'name': p.name});
    }
  }
  final noteMaps = <Map<String, dynamic>>[];
  if (criteria.includeNotes) {
    for (final n in notes) {
      if (q.isNotEmpty &&
          !n.title.toLowerCase().contains(q) &&
          !(n.content ?? '').toLowerCase().contains(q)) {
        continue;
      }
      if (criteria.tag != null &&
          criteria.tag!.isNotEmpty &&
          !n.tags.any(
            (t) => t.name.toLowerCase() == criteria.tag!.toLowerCase(),
          )) {
        continue;
      }
      noteMaps.add({
        'uid': n.uid,
        'title': n.title,
        'tags': n.tags.map((t) => t.toJson()).toList(),
      });
    }
  }
  return {
    'tasks': taskMaps,
    'projects': projectMaps,
    'notes': noteMaps,
    'offline': true,
  };
}
