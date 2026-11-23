import 'package:equatable/equatable.dart';

class TududiView extends Equatable {
  const TududiView({
    required this.id,
    required this.name,
    this.uid,
    this.searchQuery,
    this.filters = const [],
    this.priority,
    this.due,
    this.defer,
    this.tags = const [],
    this.extras = const [],
    this.isPinned = false,
  });

  final int id;
  final String name;
  final String? uid;
  final String? searchQuery;
  final List<String> filters;
  final String? priority;
  final String? due;
  final String? defer;
  final List<String> tags;
  final List<String> extras;
  final bool isPinned;

  factory TududiView.fromJson(Map<String, dynamic> json) {
    return TududiView(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
      searchQuery: json['search_query']?.toString(),
      filters: _asStringList(json['filters']),
      priority: json['priority']?.toString(),
      due: json['due']?.toString(),
      defer: json['defer']?.toString(),
      tags: _asStringList(json['tags']),
      extras: _asStringList(json['extras']),
      isPinned: json['is_pinned'] == true,
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    if (searchQuery != null) 'search_query': searchQuery,
    'filters': filters,
    if (priority != null) 'priority': priority,
    if (due != null) 'due': due,
    if (defer != null) 'defer': defer,
    'tags': tags,
    'extras': extras,
    'is_pinned': isPinned,
  };

  TududiView copyWith({
    String? name,
    String? searchQuery,
    List<String>? filters,
    String? priority,
    String? due,
    String? defer,
    List<String>? tags,
    List<String>? extras,
    bool? isPinned,
  }) {
    return TududiView(
      id: id,
      name: name ?? this.name,
      uid: uid,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      priority: priority ?? this.priority,
      due: due ?? this.due,
      defer: defer ?? this.defer,
      tags: tags ?? this.tags,
      extras: extras ?? this.extras,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uid,
    name,
    searchQuery,
    filters,
    priority,
    due,
    defer,
    tags,
    isPinned,
  ];
}

List<String> _asStringList(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item != null && item.toString().trim().isNotEmpty) item.toString(),
  ];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
