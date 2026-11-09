import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';

import '../offline/offline_write_coordinator.dart';
import '../../features/tasks/task_providers.dart';
import 'edit_desired_state.dart';
import 'edit_history.dart';
import 'edit_overlay.dart';

class _PendingSlot {
  EditDesiredState? acked;
  EditDesiredState? desired;
  Timer? timer;
}

/// Optional test hook that replaces the coordinator write path.
typedef EditApplyFn = Future<EditDesiredState> Function(
  EditDesiredState desired,
  EditDesiredState? previous,
);

/// Debounces undo/redo server writes per entity and flushes on demand.
class EditSyncCoalescer extends Notifier<int> {
  EditSyncCoalescer({
    this.debounce = const Duration(seconds: 1),
    this.applyOverride,
  });

  final Duration debounce;
  final EditApplyFn? applyOverride;
  final Map<String, _PendingSlot> _slots = {};
  int applyCount = 0;

  @override
  int build() {
    ref.onDispose(_cancelAllTimers);
    return 0;
  }

  void _cancelAllTimers() {
    for (final slot in _slots.values) {
      slot.timer?.cancel();
      slot.timer = null;
    }
  }

  void _bump() => state = state + 1;

  /// Record that the server (or outbox) already matches [state] after a user edit.
  void markAcked(EditDesiredState state) {
    final slot = _slots.putIfAbsent(state.coalesceKey, _PendingSlot.new);
    slot.timer?.cancel();
    slot.timer = null;
    slot.acked = state;
    slot.desired = state;
    _bump();
  }

  /// Schedule a coalesced sync to [desired] after [debounce].
  void schedule(EditDesiredState desired) {
    final slot = _slots.putIfAbsent(desired.coalesceKey, _PendingSlot.new);
    slot.desired = desired;
    slot.timer?.cancel();
    slot.timer = Timer(debounce, () {
      unawaited(flushKey(desired.coalesceKey));
    });
    _bump();
  }

  Future<void> flushAll() async {
    final keys = _slots.keys.toList(growable: false);
    for (final key in keys) {
      await flushKey(key);
    }
  }

  void clear() {
    _cancelAllTimers();
    _slots.clear();
    _bump();
  }

  Future<void> flushKey(String coalesceKey) async {
    final slot = _slots[coalesceKey];
    if (slot == null) return;
    slot.timer?.cancel();
    slot.timer = null;

    final desired = slot.desired;
    final acked = slot.acked;
    if (desired == null) return;
    if (acked != null && desired.sameAs(acked)) {
      _bump();
      return;
    }

    try {
      final applied = await _applyDesired(desired, previous: acked);
      slot.acked = applied;
      slot.desired = applied;
      _clearOverlayFor(applied);
      _bump();
    } catch (_) {
      // Keep desired so a later flush / lifecycle flush can retry.
      _bump();
      rethrow;
    }
  }

  void _clearOverlayFor(EditDesiredState desired) {
    final overlay = ref.read(editOverlayProvider.notifier);
    switch (desired) {
      case TaskPresentState(:final task):
        final uid = task.uid;
        if (uid != null) overlay.clearTask(uid);
      case TaskAbsentState(:final uid):
        overlay.clearTask(uid);
      case NotePresentState(:final note):
        final uid = note.uid;
        if (uid != null) overlay.clearNote(uid);
      case NoteAbsentState(:final uid):
        overlay.clearNote(uid);
    }
  }

  /// Applies [desired] and returns the state to treat as newly acked.
  Future<EditDesiredState> _applyDesired(
    EditDesiredState desired, {
    required EditDesiredState? previous,
  }) async {
    applyCount++;
    final override = applyOverride;
    if (override != null) {
      return override(desired, previous);
    }
    final coordinator = ref.read(offlineWriteCoordinatorProvider);
    switch (desired) {
      case TaskPresentState(:final task):
        final uid = task.uid;
        if (uid == null) return desired;
        if (previous is TaskAbsentState || previous == null) {
          final result = await coordinator.createTask(task.toCreateJson());
          final created = result.value;
          final newUid = created.uid;
          if (newUid != null && newUid != uid) {
            ref.read(editHistoryProvider.notifier).remapTaskUid(
                  desired.coalesceKey,
                  uid,
                  created,
                );
            _invalidateTaskLists(ref);
            return TaskPresentState(
              coalesceKey: desired.coalesceKey,
              task: created,
            );
          }
          _invalidateTaskLists(ref);
          return TaskPresentState(
            coalesceKey: desired.coalesceKey,
            task: created,
          );
        }
        final current = previous is TaskPresentState ? previous.task : task;
        // Status-only toggles (complete/undo-complete) must not rewrite name —
        // tududi stores the visible title in original_name and a full patch with
        // raw `name` was renaming tasks on undo.
        if (_isStatusOnlyChange(current, task)) {
          await coordinator.completeTask(
            uid,
            done: task.isDone,
            current: current,
          );
        } else {
          await coordinator.updateTask(
            uid,
            task.toPatchJson(),
            current: current,
          );
        }
        _invalidateTaskLists(ref, detailUid: uid);
        return desired;
      case TaskAbsentState(:final uid):
        final current = previous is TaskPresentState ? previous.task : null;
        await coordinator.deleteTask(uid, current: current);
        _invalidateTaskLists(ref, detailUid: uid);
        return desired;
      case NotePresentState(:final note):
        final uid = note.uid;
        if (uid == null) return desired;
        if (previous is NoteAbsentState || previous == null) {
          final result = await coordinator.createNote(note.toCreateJson());
          final created = result.value;
          final newUid = created.uid;
          if (newUid != null && newUid != uid) {
            ref.read(editHistoryProvider.notifier).remapNoteUid(
                  desired.coalesceKey,
                  uid,
                  created,
                );
          }
          ref.invalidate(notesProvider);
          return NotePresentState(
            coalesceKey: desired.coalesceKey,
            note: created,
          );
        }
        final current = previous is NotePresentState ? previous.note : note;
        await coordinator.updateNote(
          uid,
          note.toCreateJson(),
          current: current,
        );
        ref.invalidate(notesProvider);
        return desired;
      case NoteAbsentState(:final uid):
        final current = previous is NotePresentState ? previous.note : null;
        await coordinator.deleteNote(uid, current: current);
        ref.invalidate(notesProvider);
        return desired;
    }
  }
}

void _invalidateTaskLists(Ref ref, {String? detailUid}) {
  if (detailUid != null) {
    ref.invalidate(taskDetailProvider(detailUid));
  }
  for (final filter in TaskListFilter.values) {
    ref.invalidate(tasksProvider(filter));
  }
}

bool _isStatusOnlyChange(TududiTask from, TududiTask to) {
  return from.uid == to.uid &&
      from.displayName == to.displayName &&
      from.note == to.note &&
      from.priority == to.priority &&
      from.dueDate == to.dueDate &&
      from.projectId == to.projectId &&
      from.projectUid == to.projectUid &&
      from.status != to.status;
}

/// Default 1s debounce. Tests may override with [editSyncCoalescerProvider].
final editSyncCoalescerProvider =
    NotifierProvider<EditSyncCoalescer, int>(EditSyncCoalescer.new);
