import 'package:equatable/equatable.dart';

import 'tag.dart';

class TududiProject extends Equatable {
  const TududiProject({
    required this.id,
    required this.name,
    this.uid,
    this.description,
    this.areaId,
    this.areaUid,
    this.state,
    this.priority,
    this.dueDate,
    this.tags = const [],
    this.pinToSidebar = false,
  });

  final int id;
  final String name;
  final String? uid;
  final String? description;
  final int? areaId;
  final String? areaUid;
  final String? state;
  final String? priority;
  final String? dueDate;
  final List<TududiTag> tags;
  final bool pinToSidebar;

  factory TududiProject.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'] ?? json['Tags'];
    return TududiProject(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
      description: json['description']?.toString(),
      areaId: _asIntOrNull(json['area_id']),
      areaUid: json['area_uid']?.toString() ??
          (json['Area'] is Map ? (json['Area'] as Map)['uid']?.toString() : null),
      state: json['state']?.toString() ?? json['status']?.toString(),
      priority: json['priority']?.toString(),
      dueDate: json['due_date']?.toString(),
      tags: _parseTags(tagsJson),
      pinToSidebar: json['pin_to_sidebar'] == true || json['pinned'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (uid != null) 'uid': uid,
        if (description != null) 'description': description,
        if (areaId != null) 'area_id': areaId,
        if (areaUid != null) 'area_uid': areaUid,
        if (state != null) 'state': state,
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'due_date': dueDate,
        'tags': tags.map((t) => t.toJson()).toList(),
        'pin_to_sidebar': pinToSidebar,
      };

  @override
  List<Object?> get props =>
      [id, name, uid, description, areaId, areaUid, state, priority, dueDate];
}

List<TududiTag> _parseTags(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => TududiTag.fromJson(Map<String, dynamic>.from(e)))
      .toList();
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
