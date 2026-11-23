// Formatting helpers for the note editor toolbar / slash menu / wikilinks.

const wikilinkHrefPrefix = 'dootdoot-wikilink:';

final _wikilinkPattern = RegExp(r'\[\[([^\][\n]+?)\]\]');

/// Convert `[[Title]]` into markdown links the renderer can intercept.
String preprocessNoteWikilinks(String markdown) {
  return markdown.replaceAllMapped(_wikilinkPattern, (m) {
    final title = m.group(1)!.trim();
    final encoded = Uri.encodeComponent(title);
    return '[$title]($wikilinkHrefPrefix$encoded)';
  });
}

/// Titles referenced via `[[wikilinks]]` in [markdown].
List<String> extractWikilinkTitles(String markdown) {
  return [
    for (final m in _wikilinkPattern.allMatches(markdown)) m.group(1)!.trim(),
  ];
}

/// Notes whose content links to [title] (case-insensitive).
List<T> findBacklinks<T>({
  required Iterable<T> notes,
  required String title,
  required String Function(T) noteTitle,
  required String? Function(T) noteContent,
  required String? Function(T) noteUid,
  String? excludeUid,
}) {
  final needle = title.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final out = <T>[];
  for (final note in notes) {
    final uid = noteUid(note);
    if (excludeUid != null && uid == excludeUid) continue;
    final content = noteContent(note) ?? '';
    for (final linked in extractWikilinkTitles(content)) {
      if (linked.toLowerCase() == needle) {
        out.add(note);
        break;
      }
    }
  }
  return out;
}

/// Wrap the current selection (or insert at cursor) with [prefix]/suffix].
String wrapSelection(
  String text, {
  required int selectionStart,
  required int selectionEnd,
  required String prefix,
  required String suffix,
  String placeholder = 'text',
}) {
  final start = selectionStart.clamp(0, text.length);
  final end = selectionEnd.clamp(0, text.length);
  final selected = start < end ? text.substring(start, end) : placeholder;
  return text.replaceRange(start, end, '$prefix$selected$suffix');
}

/// Insert [block] at the start of the current line (slash-command style).
String insertBlockAtLine(
  String text, {
  required int cursor,
  required String block,
  bool replaceSlashTrigger = false,
}) {
  final pos = cursor.clamp(0, text.length);
  final lineStart = pos == 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
  var lineEnd = text.indexOf('\n', pos);
  if (lineEnd < 0) lineEnd = text.length;

  var insertAt = lineStart;
  var deleteLen = 0;
  if (replaceSlashTrigger) {
    final beforeCursor = text.substring(lineStart, pos);
    final slash = RegExp(r'(^|\s)/(\S*)$').firstMatch(beforeCursor);
    if (slash != null) {
      insertAt = lineStart + slash.start + (slash.group(1)?.length ?? 0);
      deleteLen =
          beforeCursor.length - (slash.start + (slash.group(1)?.length ?? 0));
    }
  }
  return text.replaceRange(insertAt, insertAt + deleteLen, block);
}

class SlashCommand {
  const SlashCommand({
    required this.id,
    required this.label,
    required this.keywords,
    required this.insert,
  });

  final String id;
  final String label;
  final List<String> keywords;
  final String insert;
}

const slashCommands = <SlashCommand>[
  SlashCommand(
    id: 'h1',
    label: 'Heading 1',
    keywords: ['h1', 'heading'],
    insert: '# ',
  ),
  SlashCommand(
    id: 'h2',
    label: 'Heading 2',
    keywords: ['h2', 'heading'],
    insert: '## ',
  ),
  SlashCommand(
    id: 'h3',
    label: 'Heading 3',
    keywords: ['h3', 'heading'],
    insert: '### ',
  ),
  SlashCommand(
    id: 'bold',
    label: 'Bold',
    keywords: ['bold', 'strong'],
    insert: '**text**',
  ),
  SlashCommand(
    id: 'italic',
    label: 'Italic',
    keywords: ['italic', 'em'],
    insert: '_text_',
  ),
  SlashCommand(
    id: 'strike',
    label: 'Strikethrough',
    keywords: ['strike'],
    insert: '~~text~~',
  ),
  SlashCommand(
    id: 'code',
    label: 'Inline code',
    keywords: ['code', 'inline'],
    insert: '`code`',
  ),
  SlashCommand(
    id: 'codeblock',
    label: 'Code block',
    keywords: ['codeblock', 'fence'],
    insert: '```\n\n```\n',
  ),
  SlashCommand(
    id: 'quote',
    label: 'Quote',
    keywords: ['quote', 'blockquote'],
    insert: '> ',
  ),
  SlashCommand(
    id: 'todo',
    label: 'To-do',
    keywords: ['todo', 'checkbox', 'task'],
    insert: '- [ ] ',
  ),
  SlashCommand(
    id: 'bullet',
    label: 'Bulleted list',
    keywords: ['bullet', 'ul', 'list'],
    insert: '- ',
  ),
  SlashCommand(
    id: 'number',
    label: 'Numbered list',
    keywords: ['number', 'ol'],
    insert: '1. ',
  ),
  SlashCommand(
    id: 'divider',
    label: 'Divider',
    keywords: ['divider', 'hr'],
    insert: '\n---\n',
  ),
  SlashCommand(
    id: 'link',
    label: 'Link',
    keywords: ['link', 'url'],
    insert: '[text](url)',
  ),
  SlashCommand(
    id: 'wikilink',
    label: 'Note link',
    keywords: ['note', 'wikilink', '[['],
    insert: '[[',
  ),
  SlashCommand(
    id: 'callout-note',
    label: 'Callout: Note',
    keywords: ['callout', 'note'],
    insert: '> [!NOTE]\n> ',
  ),
  SlashCommand(
    id: 'callout-tip',
    label: 'Callout: Tip',
    keywords: ['callout', 'tip'],
    insert: '> [!TIP]\n> ',
  ),
  SlashCommand(
    id: 'callout-warning',
    label: 'Callout: Warning',
    keywords: ['callout', 'warning'],
    insert: '> [!WARNING]\n> ',
  ),
  SlashCommand(
    id: 'callout-important',
    label: 'Callout: Important',
    keywords: ['callout', 'important'],
    insert: '> [!IMPORTANT]\n> ',
  ),
  SlashCommand(
    id: 'callout-danger',
    label: 'Callout: Danger',
    keywords: ['callout', 'danger'],
    insert: '> [!DANGER]\n> ',
  ),
];

List<SlashCommand> filterSlashCommands(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return slashCommands;
  return [
    for (final c in slashCommands)
      if (c.label.toLowerCase().contains(q) ||
          c.keywords.any((k) => k.contains(q) || q.contains(k)))
        c,
  ];
}
