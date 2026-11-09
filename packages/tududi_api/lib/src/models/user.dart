import 'package:equatable/equatable.dart';

class TududiUser extends Equatable {
  const TududiUser({
    required this.id,
    required this.email,
    this.name,
    this.timezone,
  });

  final int id;
  final String email;
  final String? name;
  final String? timezone;

  factory TududiUser.fromJson(Map<String, dynamic> json) {
    return TududiUser(
      id: _asInt(json['id']),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString() ?? json['username']?.toString(),
      timezone: json['timezone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (name != null) 'name': name,
        if (timezone != null) 'timezone': timezone,
      };

  @override
  List<Object?> get props => [id, email, name, timezone];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
