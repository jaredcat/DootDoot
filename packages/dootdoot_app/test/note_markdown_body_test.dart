import 'package:dootdoot_app/features/notes/note_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('tapping checkboxes reports indices and updates visuals', (
    tester,
  ) async {
    var content = '- [ ] a\n- [ ] b\n- [x] c';
    final toggled = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return NoteMarkdownBody(
                data: content,
                onCheckboxToggle: (index) {
                  toggled.add(index);
                  final next = toggleMarkdownCheckbox(content, index);
                  expect(next, isNotNull);
                  setState(() => content = next!);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNWidgets(3));
    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes.map((b) => b.value), [false, false, true]);

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();

    expect(toggled, [0, 1]);
    expect(content, contains('- [x] a'));
    expect(content, contains('- [x] b'));
    expect(content, contains('- [x] c'));

    final after = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(after.map((b) => b.value), [true, true, true]);
  });
}
