import 'package:dootdoot_app/core/providers.dart';
import 'package:dootdoot_app/features/tasks/task_list_view.dart';
import 'package:dootdoot_app/features/tasks/task_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tududi_api/tududi_api.dart';

void main() {
  testWidgets('Completed upcoming filter stays on one line', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tasksProvider.overrideWith((ref, filter) async => const <TududiTask>[]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TaskListView(filter: TaskListFilter.upcoming),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final completed = find.text('Completed');
    final idleHeight = tester.getSize(completed).height;

    await tester.tap(completed);
    await tester.pumpAndSettle();

    expect(tester.getSize(completed).height, idleHeight);
    expect(find.byIcon(Symbols.check), findsNothing);
  });
}
