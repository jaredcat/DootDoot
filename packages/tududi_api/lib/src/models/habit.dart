import 'package:equatable/equatable.dart';

class TududiHabit extends Equatable {
  const TududiHabit({
    required this.id,
    required this.name,
    this.uid,
    this.streak = 0,
    this.completedToday = false,
  });

  final int id;
  final String name;
  final String? uid;
  final int streak;
  final bool completedToday;

  factory TududiHabit.fromJson(Map<String, dynamic> json) {
    return TududiHabit(
      id: _asInt(json['id']),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      uid: json['uid']?.toString(),
      streak: _asInt(json['streak'] ?? json['current_streak']),
      completedToday: json['completed_today'] == true ||
          json['done_today'] == true,
    );
  }

  @override
  List<Object?> get props => [id, uid, name, streak, completedToday];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
