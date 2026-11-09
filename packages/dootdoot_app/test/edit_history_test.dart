import 'package:dootdoot_app/core/edit_history/edit_commands.dart';
import 'package:dootdoot_app/core/edit_history/edit_desired_state.dart';
import 'package:dootdoot_app/core/edit_history/edit_history.dart';
import 'package:dootdoot_app/core/edit_history/edit_overlay.dart';
import 'package:dootdoot_app/core/edit_history/edit_sync_coalescer.dart';
import 'package:dootdoot_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tududi_api/tududi_api.dart';

TududiTask _task({
  required String uid,
  String name = 'Task',
  int status = TaskStatus.notStarted,
  String? priority,
  String? dueDate,
}) {
  return TududiTask(
    id: 1,
    uid: uid,
    name: name,
    status: status,
    priority: priority,
    dueDate: dueDate,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late EditSyncCoalescer coalescer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    coalescer = EditSyncCoalescer(
      debounce: const Duration(hours: 1),
      applyOverride: (desired, previous) async => desired,
    );
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        editSyncCoalescerProvider.overrideWith(() => coalescer),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('push enables undo and clears redo', () {
    final history = container.read(editHistoryProvider.notifier);
    final before = _task(uid: 'a', priority: 'low');
    final after = _task(uid: 'a', priority: 'high');

    history.push(TaskUpdateCommand(before: before, after: after));
    expect(container.read(editHistoryProvider).canUndo, isTrue);
    expect(container.read(editHistoryProvider).canRedo, isFalse);

    history.undo();
    expect(container.read(editHistoryProvider).canUndo, isFalse);
    expect(container.read(editHistoryProvider).canRedo, isTrue);

    history.push(
      TaskUpdateCommand(
        before: before,
        after: _task(uid: 'a', priority: 'medium'),
      ),
    );
    expect(container.read(editHistoryProvider).canRedo, isFalse);
  });

  test('undo and redo update the local overlay', () {
    final history = container.read(editHistoryProvider.notifier);
    final before = _task(uid: 'a', priority: 'low');
    final after = _task(uid: 'a', priority: 'high');

    history.push(TaskUpdateCommand(before: before, after: after));
    expect(container.read(editOverlayProvider).tasks['a']?.priority, 'high');

    history.undo();
    expect(container.read(editOverlayProvider).tasks['a']?.priority, 'low');

    history.redo();
    expect(container.read(editOverlayProvider).tasks['a']?.priority, 'high');
  });

  test('undo then redo coalesces to zero network applies', () async {
    final history = container.read(editHistoryProvider.notifier);
    final before = _task(uid: 'a', priority: 'low');
    final after = _task(uid: 'a', priority: 'high');

    history.push(TaskUpdateCommand(before: before, after: after));
    coalescer.applyCount = 0;

    history.undo();
    history.redo();
    await coalescer.flushAll();

    expect(coalescer.applyCount, 0);
  });

  test('two undos flush as one apply with final before state', () async {
    final t0 = _task(uid: 'a', priority: 'low');
    final t1 = _task(uid: 'a', priority: 'medium');
    final t2 = _task(uid: 'a', priority: 'high');

    EditDesiredState? lastDesired;
    coalescer = EditSyncCoalescer(
      debounce: const Duration(hours: 1),
      applyOverride: (desired, previous) async {
        lastDesired = desired;
        return desired;
      },
    );
    container.dispose();
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        editSyncCoalescerProvider.overrideWith(() => coalescer),
      ],
    );

    final hist = container.read(editHistoryProvider.notifier);
    hist.push(TaskUpdateCommand(before: t0, after: t1));
    hist.push(TaskUpdateCommand(before: t1, after: t2));

    hist.undo(); // back to t1
    hist.undo(); // back to t0
    await coalescer.flushAll();

    expect(coalescer.applyCount, 1);
    expect(lastDesired, isA<TaskPresentState>());
    expect((lastDesired! as TaskPresentState).task.priority, 'low');
  });

  test('flushAll after pause path invokes pending apply', () async {
    final history = container.read(editHistoryProvider.notifier);
    final before = _task(uid: 'a', name: 'Old');
    final after = _task(uid: 'a', name: 'New');

    history.push(TaskUpdateCommand(before: before, after: after));
    coalescer.applyCount = 0;
    history.undo();
    await history.flushPending();

    expect(coalescer.applyCount, 1);
  });

  test('mergeTaskOverlay hides deleted and inserts restored', () {
    final tasks = [_task(uid: 'a'), _task(uid: 'b')];
    final merged = mergeTaskOverlay(tasks, {
      'a': null,
      'c': _task(uid: 'c', name: 'Restored'),
    });
    expect(merged.map((t) => t.uid), ['c', 'b']);
  });

  test('desired state equality detects undo-redo noop', () {
    final after = TaskPresentState(
      coalesceKey: 'task:a',
      task: _task(uid: 'a', priority: 'high'),
    );
    final again = TaskPresentState(
      coalesceKey: 'task:a',
      task: _task(uid: 'a', priority: 'high'),
    );
    final before = TaskPresentState(
      coalesceKey: 'task:a',
      task: _task(uid: 'a', priority: 'low'),
    );
    expect(after.sameAs(again), isTrue);
    expect(after.sameAs(before), isFalse);
  });
}
