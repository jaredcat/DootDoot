import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';

import '../providers.dart';
import 'edit_commands.dart';
import 'edit_desired_state.dart';
import 'edit_overlay.dart';
import 'edit_sync_coalescer.dart';

const _maxHistory = 50;

class EditHistoryState {
  const EditHistoryState({
    this.past = const [],
    this.future = const [],
  });

  final List<EditCommand> past;
  final List<EditCommand> future;

  bool get canUndo => past.isNotEmpty;
  bool get canRedo => future.isNotEmpty;

  EditHistoryState copyWith({
    List<EditCommand>? past,
    List<EditCommand>? future,
  }) {
    return EditHistoryState(
      past: past ?? this.past,
      future: future ?? this.future,
    );
  }
}

final editHistoryProvider =
    NotifierProvider<EditHistory, EditHistoryState>(EditHistory.new);

class EditHistory extends Notifier<EditHistoryState> {
  @override
  EditHistoryState build() {
    ref.listen<String?>(activeAccountIdProvider, (previous, next) {
      if (previous != next) {
        clear();
      }
    });
    return const EditHistoryState();
  }

  EditOverlayNotifier get _overlay => ref.read(editOverlayProvider.notifier);

  EditSyncCoalescer get _coalescer =>
      ref.read(editSyncCoalescerProvider.notifier);

  /// Record a successful user mutation that can later be undone.
  void push(EditCommand command) {
    final past = [...state.past, command];
    while (past.length > _maxHistory) {
      past.removeAt(0);
    }
    state = EditHistoryState(past: past, future: const []);
    // Server (or offline outbox) already has the post-edit state.
    _coalescer.markAcked(command.desiredAfterRedo);
    // Keep the after-state in the overlay so UI updates immediately while
    // providers refetch. Undo/redo and account switches still clear it.
    command.applyLocalRedo(_overlay);
  }

  /// Returns the undone command label, or null if the stack was empty.
  String? undo() {
    if (!state.canUndo) return null;
    final past = [...state.past];
    final command = past.removeLast();
    command.applyLocalUndo(_overlay);
    state = EditHistoryState(
      past: past,
      future: [...state.future, command],
    );
    _coalescer.schedule(command.desiredAfterUndo);
    return command.label;
  }

  /// Returns the redone command label, or null if the stack was empty.
  String? redo() {
    if (!state.canRedo) return null;
    final future = [...state.future];
    final command = future.removeLast();
    command.applyLocalRedo(_overlay);
    state = EditHistoryState(
      past: [...state.past, command],
      future: future,
    );
    _coalescer.schedule(command.desiredAfterRedo);
    return command.label;
  }

  void clear() {
    state = const EditHistoryState();
    _overlay.clear();
    _coalescer.clear();
  }

  Future<void> flushPending() => _coalescer.flushAll();

  void remapTaskUid(String coalesceKey, String oldUid, TududiTask newTask) {
    for (final command in [...state.past, ...state.future]) {
      if (command.coalesceKey == coalesceKey) {
        command.remapUid(oldUid, newTask);
      }
    }
    _overlay.clearTask(oldUid);
    final newUid = newTask.uid;
    if (newUid != null) {
      _overlay.setTask(newUid, newTask);
    }
    // Force listeners to rebuild with remapped commands.
    state = EditHistoryState(
      past: List.of(state.past),
      future: List.of(state.future),
    );
  }

  void remapNoteUid(String coalesceKey, String oldUid, TududiNote newNote) {
    for (final command in [...state.past, ...state.future]) {
      if (command.coalesceKey == coalesceKey) {
        command.remapNoteUid(oldUid, newNote);
      }
    }
    _overlay.clearNote(oldUid);
    final newUid = newNote.uid;
    if (newUid != null) {
      _overlay.setNote(newUid, newNote);
    }
    state = EditHistoryState(
      past: List.of(state.past),
      future: List.of(state.future),
    );
  }

}
