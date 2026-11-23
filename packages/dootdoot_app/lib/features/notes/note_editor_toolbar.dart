import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'note_format.dart';

typedef NoteFormatApply = void Function(
  String Function(
    String text, {
    required int selectionStart,
    required int selectionEnd,
  })
  transform,
);

/// Compact formatting bar for the note editor.
class NoteEditorToolbar extends StatelessWidget {
  const NoteEditorToolbar({
    super.key,
    required this.onApply,
    this.onInsertWikilink,
    this.onOpenSlash,
  });

  final NoteFormatApply onApply;
  final VoidCallback? onInsertWikilink;
  final VoidCallback? onOpenSlash;

  void _wrap(String prefix, String suffix) {
    onApply((text, {required selectionStart, required selectionEnd}) {
      return wrapSelection(
        text,
        selectionStart: selectionStart,
        selectionEnd: selectionEnd,
        prefix: prefix,
        suffix: suffix,
      );
    });
  }

  void _line(String prefix) {
    onApply((text, {required selectionStart, required selectionEnd}) {
      return insertBlockAtLine(text, cursor: selectionStart, block: prefix);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _btn(Symbols.format_bold, 'Bold', () => _wrap('**', '**')),
          _btn(Symbols.format_italic, 'Italic', () => _wrap('_', '_')),
          _btn(Symbols.strikethrough_s, 'Strike', () => _wrap('~~', '~~')),
          _btn(Symbols.code, 'Code', () => _wrap('`', '`')),
          _btn(Symbols.link, 'Link', () => _wrap('[', '](url)')),
          _btn(Symbols.title, 'H2', () => _line('## ')),
          _btn(Symbols.format_list_bulleted, 'List', () => _line('- ')),
          _btn(Symbols.check_box, 'To-do', () => _line('- [ ] ')),
          _btn(Symbols.format_quote, 'Quote', () => _line('> ')),
          if (onInsertWikilink != null)
            _btn(Symbols.note_stack, 'Note link', onInsertWikilink!),
          if (onOpenSlash != null)
            _btn(Symbols.terminal, 'Commands', onOpenSlash!),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

Future<SlashCommand?> showSlashCommandSheet(
  BuildContext context, {
  String query = '',
}) {
  return showModalBottomSheet<SlashCommand>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      var filter = query;
      return StatefulBuilder(
        builder: (context, setState) {
          final items = filterSlashCommands(filter);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Filter commands…',
                        prefixIcon: Icon(Symbols.terminal),
                      ),
                      onChanged: (v) => setState(() => filter = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final cmd = items[index];
                        return ListTile(
                          title: Text(cmd.label),
                          onTap: () => Navigator.pop(context, cmd),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
