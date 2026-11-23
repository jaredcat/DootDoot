import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'note_format.dart';

final _taskLinePattern = RegExp(
  r'^(\s*)([-*+])\s+\[([ xX])\]\s?(.*)$',
  multiLine: true,
);

/// Toggle the [index]-th GFM task-list checkbox in [markdown] (0-based).
/// Returns null if [index] is out of range.
String? toggleMarkdownCheckbox(String markdown, int index) {
  final matches = _taskLinePattern.allMatches(markdown).toList();
  if (index < 0 || index >= matches.length) return null;
  final match = matches[index];
  final checked = match.group(3)!.toLowerCase() == 'x';
  final replacement =
      '${match.group(1)}${match.group(2)} [${checked ? ' ' : 'x'}] ${match.group(4)}';
  return markdown.replaceRange(match.start, match.end, replacement);
}

/// Count GFM task-list checkboxes in [markdown].
int countMarkdownCheckboxes(String markdown) {
  return _taskLinePattern.allMatches(markdown).length;
}

/// Renders note Markdown with native task-list rows so taps stay responsive.
class NoteMarkdownBody extends StatelessWidget {
  const NoteMarkdownBody({
    super.key,
    required this.data,
    this.onCheckboxToggle,
    this.onWikilinkTap,
    this.foreground,
  });

  final String data;
  final ValueChanged<int>? onCheckboxToggle;
  final ValueChanged<String>? onWikilinkTap;
  final Color? foreground;

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    if (href.startsWith(wikilinkHrefPrefix)) {
      final title = Uri.decodeComponent(
        href.substring(wikilinkHrefPrefix.length),
      );
      onWikilinkTap?.call(title);
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  MarkdownStyleSheet _style(
    BuildContext context, {
    bool strikethrough = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final fg = foreground;
    final decoration = strikethrough
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    TextStyle? withFg(TextStyle? base) {
      if (base == null) return null;
      return base.copyWith(
        color: fg ?? base.color,
        decoration: strikethrough ? decoration : base.decoration,
        decorationColor: fg ?? base.color,
      );
    }

    return MarkdownStyleSheet(
      p: withFg(text.bodyLarge),
      h1: withFg(text.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
      h2: withFg(text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
      h3: withFg(text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      h4: withFg(text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      h5: withFg(text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      h6: withFg(text.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
      a: text.bodyLarge?.copyWith(
        color: scheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: scheme.primary,
      ),
      blockquote: withFg(
        text.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
      code: text.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: scheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      listBullet: withFg(text.bodyLarge),
      tableHead: withFg(text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      tableBody: withFg(text.bodyMedium),
      tableBorder: TableBorder.all(color: scheme.outlineVariant),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      del: withFg(
        text.bodyLarge?.copyWith(decoration: TextDecoration.lineThrough),
      ),
      strong: withFg(text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      em: withFg(text.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
    );
  }

  Widget _markdownChunk(
    BuildContext context,
    String chunk, {
    required bool isDark,
    bool strikethrough = false,
  }) {
    if (chunk.trim().isEmpty) return const SizedBox.shrink();
    return MarkdownBody(
      data: preprocessNoteWikilinks(chunk),
      selectable: false,
      shrinkWrap: true,
      styleSheet: _style(context, strikethrough: strikethrough),
      softLineBreak: true,
      builders: {'pre': _HighlightedCodeBuilder(isDark: isDark)},
      onTapLink: (text, href, title) => _openLink(href),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lines = data.split('\n');
    final children = <Widget>[];
    final buffer = StringBuffer();
    var taskIndex = 0;

    void flushMarkdown() {
      if (buffer.isEmpty) return;
      final chunk = buffer.toString();
      buffer.clear();
      children.add(_markdownChunk(context, chunk, isDark: isDark));
    }

    for (final line in lines) {
      final match = _taskLinePattern.firstMatch(line);
      if (match == null) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(line);
        continue;
      }

      flushMarkdown();
      final indent = match.group(1) ?? '';
      final checked = match.group(3)!.toLowerCase() == 'x';
      final label = match.group(4) ?? '';
      final index = taskIndex++;
      final indentPx = indent.replaceAll('\t', '    ').length * 8.0;

      children.add(
        Padding(
          padding: EdgeInsets.only(left: indentPx, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
                onChanged: onCheckboxToggle == null
                    ? null
                    : (_) => onCheckboxToggle!(index),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: label.isEmpty
                      ? const SizedBox(height: 20)
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onCheckboxToggle == null
                              ? null
                              : () => onCheckboxToggle!(index),
                          child: _markdownChunk(
                            context,
                            label,
                            isDark: isDark,
                            strikethrough: checked,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    flushMarkdown();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _HighlightedCodeBuilder extends MarkdownElementBuilder {
  _HighlightedCodeBuilder({required this.isDark});

  final bool isDark;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final codeElement = element.children
        ?.whereType<md.Element>()
        .where((e) => e.tag == 'code')
        .firstOrNull;
    final raw = codeElement?.textContent ?? element.textContent;
    var language = 'plaintext';
    final className = codeElement?.attributes['class'] ?? '';
    final match = RegExp(r'language-(\w+)').firstMatch(className);
    if (match != null) language = match.group(1)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (language != 'plaintext')
              Container(
                color: isDark
                    ? const Color(0xFF2C313A)
                    : const Color(0xFFECEFF4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  language,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFABB2BF)
                        : const Color(0xFF5C6370),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            HighlightView(
              raw,
              language: language,
              theme: isDark ? atomOneDarkTheme : githubTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
