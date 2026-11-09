import 'package:equatable/equatable.dart';

import 'tag.dart';

class TududiNote extends Equatable {
  const TududiNote({
    required this.id,
    required this.title,
    this.uid,
    this.content,
    this.projectId,
    this.projectUid,
    this.tags = const [],
    this.updatedAt,
  });

  final int id;
  final String title;
  final String? uid;
  final String? content;
  final int? projectId;
  final String? projectUid;
  final List<TududiTag> tags;
  final String? updatedAt;

  factory TududiNote.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'] ?? json['Tags'];
    return TududiNote(
      id: _asInt(json['id']),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
      content: json['content']?.toString() ?? json['body']?.toString(),
      projectId: _asIntOrNull(json['project_id']),
      projectUid: json['project_uid']?.toString(),
      tags: _parseTags(tagsJson),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'title': title,
        if (content != null) 'content': content,
        if (projectId != null) 'project_id': projectId,
        if (projectUid != null) 'project_uid': projectUid,
      };

  TududiNote copyWith({
    String? title,
    String? content,
    int? projectId,
    String? projectUid,
  }) {
    return TududiNote(
      id: id,
      title: title ?? this.title,
      uid: uid,
      content: content ?? this.content,
      projectId: projectId ?? this.projectId,
      projectUid: projectUid ?? this.projectUid,
      tags: tags,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, uid, title, content, projectId];
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
