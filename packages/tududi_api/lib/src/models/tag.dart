import 'package:equatable/equatable.dart';

class TududiTag extends Equatable {
  const TududiTag({
    required this.id,
    required this.name,
    this.uid,
  });

  final int id;
  final String name;
  final String? uid;

  factory TududiTag.fromJson(Map<String, dynamic> json) {
    return TududiTag(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (uid != null) 'uid': uid,
      };

  @override
  List<Object?> get props => [id, name, uid];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
