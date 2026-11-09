import 'package:equatable/equatable.dart';

class TududiGoal extends Equatable {
  const TududiGoal({
    required this.id,
    required this.title,
    this.uid,
    this.why,
    this.horizon = 'season',
    this.targetDate,
    this.status = 'active',
  });

  final int id;
  final String title;
  final String? uid;
  final String? why;
  final String horizon;
  final String? targetDate;
  final String status;

  factory TududiGoal.fromJson(Map<String, dynamic> json) {
    return TududiGoal(
      id: _asInt(json['id']),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      uid: json['uid']?.toString(),
      why: json['why']?.toString(),
      horizon: (json['horizon'] ?? 'season').toString(),
      targetDate: json['target_date']?.toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  @override
  List<Object?> get props => [id, uid, title, horizon, status];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
