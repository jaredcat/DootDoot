import 'package:tududi_api/tududi_api.dart';
import 'package:uuid/uuid.dart';

import 'edit_desired_state.dart';
import 'edit_overlay.dart';

/// A reversible user edit. Local apply is sync; server sync is coalesced.
abstract class EditCommand {
  String get label;
  String get coalesceKey;

  void applyLocalUndo(EditOverlayNotifier overlay);
  void applyLocalRedo(EditOverlayNotifier overlay);

  EditDesiredState get desiredAfterUndo;
  EditDesiredState get desiredAfterRedo;

  /// Called when a recreate assigns a new server uid.
  void remapUid(String oldUid, TududiTask newTask) {}
  void remapNoteUid(String oldUid, TududiNote newNote) {}
}

class TaskCreateCommand extends EditCommand {
  TaskCreateCommand(TududiTask task)
      : assert(task.uid != null && task.uid!.isNotEmpty),
        _historyId = const Uuid().v4(),
        _task = task;

  final String _historyId;
  TududiTask _task;

  TududiTask get task => _task;

  @override
  String get label => 'Create task';

  @override
  String get coalesceKey => 'task-create:$_historyId';

  String get uid => _task.uid!;

  @override
  void applyLocalUndo(EditOverlayNotifier overlay) {
    overlay.setTask(uid, null);
  }

  @override
  void applyLocalRedo(EditOverlayNotifier overlay) {
    overlay.setTask(uid, _task);
  }

  @override
  EditDesiredState get desiredAfterUndo => TaskAbsentState(
        coalesceKey: coalesceKey,
        uid: uid,
      );

  @override
  EditDesiredState get desiredAfterRedo => TaskPresentState(
        coalesceKey: coalesceKey,
        task: _task,
      );

  @override
  void remapUid(String oldUid, TududiTask newTask) {
    if (_task.uid == oldUid) {
      _task = newTask;
    }
  }
}

class TaskUpdateCommand extends EditCommand {
  TaskUpdateCommand({
    required this.before,
    required this.after,
    String? label,
  })  : assert(before.uid != null && before.uid == after.uid),
        _label = label ?? _defaultLabel(before, after);

  final TududiTask before;
  final TududiTask after;
  final String _label;

  static String _defaultLabel(TududiTask before, TududiTask after) {
    if (before.status != after.status &&
        before.displayName == after.displayName &&
        before.note == after.note &&
        before.priority == after.priority &&
        before.dueDate == after.dueDate &&
        before.projectId == after.projectId &&
        before.projectUid == after.projectUid) {
      if (after.isDone && !before.isDone) return 'Complete task';
      if (!after.isDone && before.isDone) return 'Uncomplete task';
      return 'Change task status';
    }
    return 'Update task';
  }

  @override
  String get label => _label;

  @override
  String get coalesceKey => 'task:${before.uid}';

  @override
  void applyLocalUndo(EditOverlayNotifier overlay) {
    overlay.setTask(before.uid!, before);
  }

  @override
  void applyLocalRedo(EditOverlayNotifier overlay) {
    overlay.setTask(after.uid!, after);
  }

  @override
  EditDesiredState get desiredAfterUndo => TaskPresentState(
        coalesceKey: coalesceKey,
        task: before,
      );

  @override
  EditDesiredState get desiredAfterRedo => TaskPresentState(
        coalesceKey: coalesceKey,
        task: after,
      );
}

class TaskDeleteCommand extends EditCommand {
  TaskDeleteCommand(TududiTask task)
      : assert(task.uid != null && task.uid!.isNotEmpty),
        _historyId = const Uuid().v4(),
        _task = task;

  final String _historyId;
  TududiTask _task;

  TududiTask get task => _task;

  @override
  String get label => 'Delete task';

  @override
  String get coalesceKey => 'task-delete:$_historyId';

  String get uid => _task.uid!;

  @override
  void applyLocalUndo(EditOverlayNotifier overlay) {
    overlay.setTask(uid, _task);
  }

  @override
  void applyLocalRedo(EditOverlayNotifier overlay) {
    overlay.setTask(uid, null);
  }

  @override
  EditDesiredState get desiredAfterUndo => TaskPresentState(
        coalesceKey: coalesceKey,
        task: _task,
      );

  @override
  EditDesiredState get desiredAfterRedo => TaskAbsentState(
        coalesceKey: coalesceKey,
        uid: uid,
      );

  @override
  void remapUid(String oldUid, TududiTask newTask) {
    if (_task.uid == oldUid) {
      _task = newTask;
    }
  }
}

class NoteCreateCommand extends EditCommand {
  NoteCreateCommand(TududiNote note)
      : assert(note.uid != null && note.uid!.isNotEmpty),
        _historyId = const Uuid().v4(),
        _note = note;

  final String _historyId;
  TududiNote _note;

  TududiNote get note => _note;

  @override
  String get label => 'Create note';

  @override
  String get coalesceKey => 'note-create:$_historyId';

  String get uid => _note.uid!;

  @override
  void applyLocalUndo(EditOverlayNotifier overlay) {
    overlay.setNote(uid, null);
  }

  @override
  void applyLocalRedo(EditOverlayNotifier overlay) {
    overlay.setNote(uid, _note);
  }

  @override
  EditDesiredState get desiredAfterUndo => NoteAbsentState(
        coalesceKey: coalesceKey,
        uid: uid,
      );

  @override
  EditDesiredState get desiredAfterRedo => NotePresentState(
        coalesceKey: coalesceKey,
        note: _note,
      );

  @override
  void remapNoteUid(String oldUid, TududiNote newNote) {
    if (_note.uid == oldUid) {
      _note = newNote;
    }
  }
}

class NoteUpdateCommand extends EditCommand {
  NoteUpdateCommand({
    required this.before,
    required this.after,
  }) : assert(before.uid != null && before.uid == after.uid);

  final TududiNote before;
  final TududiNote after;

  @override
  String get label => 'Update note';

  @override
  String get coalesceKey => 'note:${before.uid}';

  @override
  void applyLocalUndo(EditOverlayNotifier overlay) {
    overlay.setNote(before.uid!, before);
  }

  @override
  void applyLocalRedo(EditOverlayNotifier overlay) {
    overlay.setNote(after.uid!, after);
  }

  @override
  EditDesiredState get desiredAfterUndo => NotePresentState(
        coalesceKey: coalesceKey,
        note: before,
      );

  @override
  EditDesiredState get desiredAfterRedo => NotePresentState(
        coalesceKey: coalesceKey,
        note: after,
      );
}

class NoteDeleteCommand extends EditCommand {
  NoteDeleteCommand(TududiNote note)
      : assert(note.uid != null && note.uid!.isNotEmpty),
        _historyId = const Uuid().v4(),
        _note = note;

  final String _historyId;
  TududiNote _note;

  TududiNote get note => _note;

  @override
  String get label => 'Delete note';

  @override
  String get coalesceKey => 'note-delete:$_historyId';

  String get uid => _note.uid!;

  @override
  void applyLocalUndo(EditOverlayNotifier overlay) {
    overlay.setNote(uid, _note);
  }

  @override
  void applyLocalRedo(EditOverlayNotifier overlay) {
    overlay.setNote(uid, null);
  }

  @override
  EditDesiredState get desiredAfterUndo => NotePresentState(
        coalesceKey: coalesceKey,
        note: _note,
      );

  @override
  EditDesiredState get desiredAfterRedo => NoteAbsentState(
        coalesceKey: coalesceKey,
        uid: uid,
      );

  @override
  void remapNoteUid(String oldUid, TududiNote newNote) {
    if (_note.uid == oldUid) {
      _note = newNote;
    }
  }
}
