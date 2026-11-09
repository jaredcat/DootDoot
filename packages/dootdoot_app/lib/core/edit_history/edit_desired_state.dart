import 'package:tududi_api/tududi_api.dart';

/// Desired server-visible state for one coalesced entity key.
sealed class EditDesiredState {
  const EditDesiredState({required this.coalesceKey});

  final String coalesceKey;

  bool sameAs(EditDesiredState other);
}

class TaskPresentState extends EditDesiredState {
  const TaskPresentState({
    required super.coalesceKey,
    required this.task,
  });

  final TududiTask task;

  String? get uid => task.uid;

  @override
  bool sameAs(EditDesiredState other) {
    if (other is! TaskPresentState) return false;
    if (coalesceKey != other.coalesceKey) return false;
    return _taskFieldsEqual(task, other.task);
  }
}

class TaskAbsentState extends EditDesiredState {
  const TaskAbsentState({
    required super.coalesceKey,
    required this.uid,
  });

  final String uid;

  @override
  bool sameAs(EditDesiredState other) {
    return other is TaskAbsentState &&
        coalesceKey == other.coalesceKey &&
        uid == other.uid;
  }
}

class NotePresentState extends EditDesiredState {
  const NotePresentState({
    required super.coalesceKey,
    required this.note,
  });

  final TududiNote note;

  String? get uid => note.uid;

  @override
  bool sameAs(EditDesiredState other) {
    if (other is! NotePresentState) return false;
    if (coalesceKey != other.coalesceKey) return false;
    return _noteFieldsEqual(note, other.note);
  }
}

class NoteAbsentState extends EditDesiredState {
  const NoteAbsentState({
    required super.coalesceKey,
    required this.uid,
  });

  final String uid;

  @override
  bool sameAs(EditDesiredState other) {
    return other is NoteAbsentState &&
        coalesceKey == other.coalesceKey &&
        uid == other.uid;
  }
}

bool _taskFieldsEqual(TududiTask a, TududiTask b) {
  return a.uid == b.uid &&
      a.displayName == b.displayName &&
      a.note == b.note &&
      a.status == b.status &&
      a.priority == b.priority &&
      a.dueDate == b.dueDate &&
      a.projectId == b.projectId &&
      a.projectUid == b.projectUid;
}

bool _noteFieldsEqual(TududiNote a, TududiNote b) {
  return a.uid == b.uid &&
      a.title == b.title &&
      a.content == b.content &&
      a.projectId == b.projectId &&
      a.projectUid == b.projectUid;
}
