import 'package:dootdoot_app/features/notes/note_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toggleMarkdownCheckbox', () {
    test('toggles first unchecked item', () {
      const src = '''
## Ingredients
- [ ] pineapple
- [ ] orange
- [x] done
''';
      final next = toggleMarkdownCheckbox(src, 0);
      expect(next, contains('- [x] pineapple'));
      expect(next, contains('- [ ] orange'));
      expect(next, contains('- [x] done'));
    });

    test('toggles checked item back to unchecked', () {
      const src = '- [x] done\n- [ ] next';
      final next = toggleMarkdownCheckbox(src, 0);
      expect(next, '- [ ] done\n- [ ] next');
    });

    test('supports asterisk bullets and indentation', () {
      const src = '  * [ ] nested';
      expect(toggleMarkdownCheckbox(src, 0), '  * [x] nested');
    });
  });

  group('countMarkdownCheckboxes', () {
    test('counts all task items', () {
      const src = '''
- [ ] a
- [x] b
not a box
1. ordered
- plain
''';
      expect(countMarkdownCheckboxes(src), 2);
    });
  });
}
