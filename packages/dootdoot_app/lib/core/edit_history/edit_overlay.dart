import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';

/// In-memory optimistic patches applied on undo/redo before server flush.
///
/// A `null` value means the entity is deleted locally.
class EditOverlay {
  const EditOverlay({
    this.tasks = const {},
    this.notes = const {},
  });

  final Map<String, TududiTask?> tasks;
  final Map<String, TududiNote?> notes;

  bool get isEmpty => tasks.isEmpty && notes.isEmpty;
}

final editOverlayProvider =
    NotifierProvider<EditOverlayNotifier, EditOverlay>(EditOverlayNotifier.new);

class EditOverlayNotifier extends Notifier<EditOverlay> {
  @override
  EditOverlay build() => const EditOverlay();

  void setTask(String uid, TududiTask? task) {
    state = EditOverlay(
      tasks: {...state.tasks, uid: task},
      notes: state.notes,
    );
  }

  void clearTask(String uid) {
    if (!state.tasks.containsKey(uid)) return;
    final next = Map<String, TududiTask?>.from(state.tasks)..remove(uid);
    state = EditOverlay(tasks: next, notes: state.notes);
  }

  void setNote(String uid, TududiNote? note) {
    state = EditOverlay(
      tasks: state.tasks,
      notes: {...state.notes, uid: note},
    );
  }

  void clearNote(String uid) {
    if (!state.notes.containsKey(uid)) return;
    final next = Map<String, TududiNote?>.from(state.notes)..remove(uid);
    state = EditOverlay(tasks: state.tasks, notes: next);
  }

  void clear() => state = const EditOverlay();
}

List<TududiTask> mergeTaskOverlay(
  List<TududiTask> tasks,
  Map<String, TududiTask?> overlay,
) {
  if (overlay.isEmpty) return tasks;
  final result = <TududiTask>[];
  final seen = <String>{};
  for (final task in tasks) {
    final uid = task.uid;
    if (uid == null) {
      result.add(task);
      continue;
    }
    if (overlay.containsKey(uid)) {
      seen.add(uid);
      final patched = overlay[uid];
      if (patched != null) result.add(patched);
    } else {
      result.add(task);
    }
  }
  for (final entry in overlay.entries) {
    if (seen.contains(entry.key)) continue;
    final task = entry.value;
    if (task != null) result.insert(0, task);
  }
  return result;
}

List<TududiNote> mergeNoteOverlay(
  List<TududiNote> notes,
  Map<String, TududiNote?> overlay,
) {
  if (overlay.isEmpty) return notes;
  final result = <TududiNote>[];
  final seen = <String>{};
  for (final note in notes) {
    final uid = note.uid;
    if (uid == null) {
      result.add(note);
      continue;
    }
    if (overlay.containsKey(uid)) {
      seen.add(uid);
      final patched = overlay[uid];
      if (patched != null) result.add(patched);
    } else {
      result.add(note);
    }
  }
  for (final entry in overlay.entries) {
    if (seen.contains(entry.key)) continue;
    final note = entry.value;
    if (note != null) result.insert(0, note);
  }
  return result;
}

TududiTask? overlayTaskOr(String uid, TududiTask? fallback, EditOverlay overlay) {
  if (overlay.tasks.containsKey(uid)) return overlay.tasks[uid];
  return fallback;
}
