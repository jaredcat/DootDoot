import 'package:equatable/equatable.dart';

class TududiArea extends Equatable {
  const TududiArea({
    required this.id,
    required this.name,
    this.uid,
    this.description,
  });

  final int id;
  final String name;
  final String? uid;
  final String? description;

  factory TududiArea.fromJson(Map<String, dynamic> json) {
    return TududiArea(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (uid != null) 'uid': uid,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => [id, name, uid, description];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
