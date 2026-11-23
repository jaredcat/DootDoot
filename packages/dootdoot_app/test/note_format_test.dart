import 'package:dootdoot_app/features/notes/note_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preprocessNoteWikilinks converts titles', () {
    final out = preprocessNoteWikilinks('See [[Alpha]] and [[Beta Note]]');
    expect(out, contains(']($wikilinkHrefPrefix'));
    expect(out, contains(Uri.encodeComponent('Alpha')));
    expect(out, contains(Uri.encodeComponent('Beta Note')));
  });

  test('extractWikilinkTitles', () {
    expect(extractWikilinkTitles('[[One]] plain [[Two]]'), ['One', 'Two']);
  });

  test('wrapSelection and insertBlockAtLine', () {
    expect(
      wrapSelection(
        'hello',
        selectionStart: 0,
        selectionEnd: 5,
        prefix: '**',
        suffix: '**',
      ),
      '**hello**',
    );
    expect(insertBlockAtLine('body', cursor: 0, block: '## '), '## body');
    expect(
      insertBlockAtLine(
        '/todo more',
        cursor: 5,
        block: '- [ ] ',
        replaceSlashTrigger: true,
      ),
      '- [ ]  more',
    );
    // cursor after "/todo" (index 5) replaces the slash token only.
  });
}
