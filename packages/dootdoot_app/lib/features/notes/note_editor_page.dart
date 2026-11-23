import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/edit_history/edit_commands.dart';
import '../../core/edit_history/edit_history.dart';
import '../../core/offline/offline_write_coordinator.dart';
import '../../core/providers.dart';
import '../tasks/tag_picker.dart';
import '../tasks/task_providers.dart';
import 'note_colors.dart';
import 'note_editor_toolbar.dart';
import 'note_format.dart';
import 'note_markdown.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, required this.uid});

  final String? uid;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocus = FocusNode();
  bool _loading = true;
  bool _saving = false;
  late bool _editing = widget.uid == null;
  TududiNote? _current;
  List<TududiTag> _tags = const [];
  int? _projectId;
  String? _projectUid;
  String? _projectName;
  String? _color;

  /// View-mode body; kept separate so checkbox toggles don't fight the editor controller.
  String _displayContent = '';
  bool _checkboxPersistInFlight = false;
  String? _pendingCheckboxContent;

  /// Bumped on every local checkbox edit; persist must not clobber newer local text.
  int _contentEpoch = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _load();
  }

  void _onContentChanged() {
    if (!_editing) return;
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (!sel.isValid) return;
    final pos = sel.baseOffset;
    if (pos < 0 || pos > text.length) return;

    // Auto-open slash menu when `/` starts a token at line start / after space.
    if (pos >= 1 && text[pos - 1] == '/') {
      final before = pos >= 2 ? text[pos - 2] : '\n';
      if (before == '\n' || before == ' ') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _runSlashCommand(query: '');
        });
      }
    }

    // Auto-open note picker after `[[`.
    if (pos >= 2 && text.substring(pos - 2, pos) == '[[') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _insertWikilink(replaceTrigger: true);
      });
    }
  }

  void _applyNote(TududiNote note) {
    _current = note;
    _titleController.text = note.title;
    final content = note.content ?? '';
    _contentController.text = content;
    _displayContent = content;
    _tags = note.tags;
    _projectId = note.projectId;
    _projectUid = note.projectUid;
    _color = note.color;
  }

  Future<void> _resolveProjectName() async {
    if (_projectId == null && _projectUid == null) {
      _projectName = null;
      return;
    }
    try {
      final projects = await ref.read(projectsProvider.future);
      for (final p in projects) {
        if ((_projectUid != null && p.uid == _projectUid) ||
            p.id == _projectId) {
          _projectName = p.name;
          return;
        }
      }
    } catch (_) {}
    _projectName = null;
  }

  Future<void> _load() async {
    if (widget.uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client != null) {
        try {
          final note = await client.getNote(widget.uid!);
          _applyNote(note);
          await _resolveProjectName();
          return;
        } catch (_) {}
      }
      final account = ref.read(activeAccountProvider);
      final isPro = ref.read(proControllerProvider);
      if (account != null && isPro) {
        final cache = ref.read(offlineCacheProvider);
        final raw = await cache.getJson(account.id, 'notes');
        if (raw is List) {
          for (final item in raw.whereType<Map>()) {
            final note = TududiNote.fromJson(Map<String, dynamic>.from(item));
            if (note.uid == widget.uid) {
              _applyNote(note);
              await _resolveProjectName();
              break;
            }
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startEditing() {
    _contentController.value = TextEditingValue(
      text: _displayContent,
      selection: TextSelection.collapsed(offset: _displayContent.length),
    );
    setState(() => _editing = true);
  }

  Future<void> _cancelEditing() async {
    if (widget.uid == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final note = _current;
    if (note != null) {
      _applyNote(note);
      await _resolveProjectName();
    }
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _pickTags() async {
    if (!_editing) return;
    final all = await ref.read(tagsProvider.future);
    if (!mounted) return;
    final names = await showTagPicker(context, selected: _tags, allTags: all);
    if (names == null || !mounted) return;
    setState(() {
      _tags = [
        for (var i = 0; i < names.length; i++) TududiTag(id: i, name: names[i]),
      ];
    });
  }

  Future<void> _pickProject() async {
    if (!_editing) return;
    final projects = await ref.read(projectsProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('No project'),
                trailing: _projectId == null && _projectUid == null
                    ? const Icon(Symbols.check)
                    : null,
                onTap: () => Navigator.of(context).pop('none'),
              ),
              for (final project in projects)
                ListTile(
                  title: Text(project.name),
                  trailing:
                      (project.uid != null && project.uid == _projectUid) ||
                          project.id == _projectId
                      ? const Icon(Symbols.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(project),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (selected == 'none') {
        _projectId = null;
        _projectUid = null;
        _projectName = null;
      } else {
        final project = selected as TududiProject;
        _projectId = project.id;
        _projectUid = project.uid;
        _projectName = project.name;
      }
    });
  }

  Future<void> _pickColor() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Color', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('None'),
                      selected: _color == null || _color!.isEmpty,
                      onSelected: (_) => Navigator.pop(context, ''),
                    ),
                    for (final c in notePalette)
                      InkWell(
                        onTap: () => Navigator.pop(context, c.key),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == c.key || _color == _hex(c.value)
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _color = selected.isEmpty ? null : selected);
    if (widget.uid != null) {
      await _persistContent(_contentController.text);
    }
  }

  String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  Map<String, dynamic> _noteBody({required String content}) => {
    'title': _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim(),
    'content': content,
    'tags': _tags.map((t) => t.name).toList(),
    'project_id': _projectId,
    'project_uid': _projectUid,
    'color': _color,
  };

  Future<void> _persistContent(
    String content, {
    bool leaveEditing = false,
    bool showBusy = true,
    bool invalidateList = true,
    int? epoch,
  }) async {
    final uid = widget.uid;
    if (uid == null) return;
    if (showBusy) setState(() => _saving = true);
    try {
      final before = _current;
      final result = await ref
          .read(offlineWriteCoordinatorProvider)
          .updateNote(uid, _noteBody(content: content), current: before);
      if (before != null) {
        ref
            .read(editHistoryProvider.notifier)
            .push(NoteUpdateCommand(before: before, after: result.value));
      }
      _current = result.value;
      // Checkbox saves must not rewrite the viewer — optimistic text is source of
      // truth until the user reloads or exits edit mode.
      final isCheckboxSave = epoch != null;
      final responseIsLatest = epoch == null || epoch == _contentEpoch;
      if (!_editing && responseIsLatest && !isCheckboxSave) {
        _displayContent = result.value.content ?? content;
      }
      if (responseIsLatest && !isCheckboxSave) {
        _tags = result.value.tags;
        _projectId = result.value.projectId;
        _projectUid = result.value.projectUid;
        _color = result.value.color;
      }
      if (invalidateList) ref.invalidate(notesProvider);
      if (!mounted) return;
      if (leaveEditing) {
        setState(() => _editing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted && showBusy) setState(() => _saving = false);
    }
  }

  void _toggleCheckbox(int index) {
    if (widget.uid == null) return;
    final next = toggleMarkdownCheckbox(_displayContent, index);
    if (next == null) return;
    _contentEpoch++;
    setState(() => _displayContent = next);
    _queueCheckboxPersist(next, _contentEpoch);
  }

  Future<void> _queueCheckboxPersist(String content, int epoch) async {
    _pendingCheckboxContent = content;
    if (_checkboxPersistInFlight) return;
    _checkboxPersistInFlight = true;
    try {
      while (_pendingCheckboxContent != null) {
        final toSave = _pendingCheckboxContent!;
        final saveEpoch = _contentEpoch;
        _pendingCheckboxContent = null;
        await _persistContent(
          toSave,
          showBusy: false,
          invalidateList: false,
          epoch: saveEpoch,
        );
      }
      if (mounted) ref.invalidate(notesProvider);
    } finally {
      _checkboxPersistInFlight = false;
    }
  }

  void _applyFormat(
    String Function(
      String text, {
      required int selectionStart,
      required int selectionEnd,
    })
    transform,
  ) {
    final sel = _contentController.selection;
    final start = sel.isValid ? sel.start : _contentController.text.length;
    final end = sel.isValid ? sel.end : start;
    final next = transform(
      _contentController.text,
      selectionStart: start,
      selectionEnd: end,
    );
    setState(() {
      _contentController.text = next;
      _contentController.selection = TextSelection.collapsed(
        offset: next.length,
      );
    });
    _contentFocus.requestFocus();
  }

  Future<void> _runSlashCommand({String query = ''}) async {
    final cmd = await showSlashCommandSheet(context, query: query);
    if (cmd == null || !mounted) return;
    if (cmd.id == 'wikilink') {
      await _insertWikilink(replaceTrigger: true);
      return;
    }
    final sel = _contentController.selection;
    final cursor = sel.isValid
        ? sel.baseOffset
        : _contentController.text.length;
    final next = insertBlockAtLine(
      _contentController.text,
      cursor: cursor,
      block: cmd.insert,
      replaceSlashTrigger: true,
    );
    setState(() {
      _contentController.text = next;
      _contentController.selection = TextSelection.collapsed(
        offset: cursor + cmd.insert.length,
      );
    });
  }

  Future<void> _insertWikilink({bool replaceTrigger = false}) async {
    List<TududiNote> notes;
    try {
      notes = await ref.read(notesProvider.future);
    } catch (_) {
      notes = const [];
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        var filter = '';
        return StatefulBuilder(
          builder: (context, setModal) {
            final filtered = [
              for (final n in notes)
                if (filter.isEmpty ||
                    n.title.toLowerCase().contains(filter.toLowerCase()))
                  n,
            ];
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Link to note…',
                          prefixIcon: Icon(Symbols.note_stack),
                        ),
                        onChanged: (v) => setModal(() => filter = v),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          if (filter.trim().isNotEmpty)
                            ListTile(
                              leading: const Icon(Symbols.add),
                              title: Text('Use “${filter.trim()}”'),
                              onTap: () =>
                                  Navigator.pop(context, filter.trim()),
                            ),
                          for (final n in filtered)
                            ListTile(
                              title: Text(
                                n.title.isEmpty ? 'Untitled' : n.title,
                              ),
                              onTap: () => Navigator.pop(
                                context,
                                n.title.isEmpty ? 'Untitled' : n.title,
                              ),
                            ),
                        ],
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
    if (picked == null || !mounted) return;
    final sel = _contentController.selection;
    final cursor = sel.isValid
        ? sel.baseOffset
        : _contentController.text.length;
    var text = _contentController.text;
    var insertAt = cursor;
    if (replaceTrigger &&
        cursor >= 2 &&
        text.substring(cursor - 2, cursor) == '[[') {
      insertAt = cursor - 2;
      text = text.replaceRange(insertAt, cursor, '');
    } else if (replaceTrigger) {
      // Also strip a trailing slash-command remnant if any.
      text = insertBlockAtLine(
        text,
        cursor: cursor,
        block: '',
        replaceSlashTrigger: true,
      );
      insertAt = text.length < cursor ? text.length : cursor;
    }
    final link = '[[$picked]]';
    final next = text.replaceRange(insertAt, insertAt, link);
    setState(() {
      _contentController.text = next;
      _contentController.selection = TextSelection.collapsed(
        offset: insertAt + link.length,
      );
    });
    _contentFocus.requestFocus();
  }

  Future<void> _openWikilink(String title) async {
    try {
      final notes = await ref.read(notesProvider.future);
      for (final n in notes) {
        if (n.title.toLowerCase() == title.toLowerCase() && n.uid != null) {
          if (!mounted) return;
          context.push('/more/notes/${n.uid}');
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Note “$title” not found')));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = _noteBody(content: _contentController.text);
      final coordinator = ref.read(offlineWriteCoordinatorProvider);
      final OfflineMutationResult<TududiNote> result;
      final isNew = widget.uid == null;
      if (isNew) {
        result = await coordinator.createNote(body);
        final created = result.value;
        if (created.uid != null) {
          ref
              .read(editHistoryProvider.notifier)
              .push(NoteCreateCommand(created));
        }
      } else {
        final before = _current;
        result = await coordinator.updateNote(
          widget.uid!,
          body,
          current: before,
        );
        if (before != null) {
          ref
              .read(editHistoryProvider.notifier)
              .push(NoteUpdateCommand(before: before, after: result.value));
        }
      }
      ref.invalidate(notesProvider);
      ref.invalidate(tagsProvider);
      if (!mounted) return;
      final msg = offlineQueuedMessage(result);
      if (msg != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      if (isNew) {
        Navigator.pop(context);
        return;
      }
      _applyNote(result.value);
      await _resolveProjectName();
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = resolveNoteColor(_color);
    final surface = noteSurfaceColor(palette, isDark: isDark);
    final fg = noteForegroundOn(palette, isDark: isDark);
    final title = widget.uid == null
        ? 'New note'
        : (_editing
              ? 'Edit note'
              : (_titleController.text.trim().isEmpty
                    ? 'Note'
                    : _titleController.text.trim()));

    return Scaffold(
      backgroundColor: palette == null ? null : surface,
      appBar: AppBar(
        backgroundColor: palette == null ? null : surface,
        foregroundColor: fg,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Color',
            onPressed: _loading ? null : _pickColor,
            icon: const Icon(Symbols.palette),
          ),
          if (_editing) ...[
            if (widget.uid != null)
              IconButton(
                tooltip: 'Cancel',
                onPressed: _saving || _loading ? null : _cancelEditing,
                icon: const Icon(Symbols.close),
              ),
            IconButton(
              tooltip: 'Save',
              onPressed: _saving || _loading ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.check),
            ),
          ] else
            IconButton(
              tooltip: 'Edit',
              onPressed: _loading ? null : _startEditing,
              icon: const Icon(Symbols.edit),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _editing
          ? _buildEditor(context, fg)
          : _buildViewer(context, fg),
    );
  }

  Widget _buildViewer(BuildContext context, Color? fg) {
    final displayTitle = _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim();
    final content = _displayContent;
    final projectLabel = _projectName?.isNotEmpty == true
        ? _projectName!
        : null;
    final scheme = Theme.of(context).colorScheme;
    final muted = fg?.withValues(alpha: 0.7) ?? scheme.onSurfaceVariant;
    final notes =
        ref.watch(notesProvider).asData?.value ?? const <TududiNote>[];
    final backlinks = findBacklinks(
      notes: notes,
      title: displayTitle,
      noteTitle: (n) => n.title,
      noteContent: (n) => n.content,
      noteUid: (n) => n.uid,
      excludeUid: widget.uid,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          displayTitle,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w600, color: fg),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (projectLabel != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.folder, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    projectLabel,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: muted),
                  ),
                ],
              ),
            for (final tag in _tags)
              Chip(
                label: Text(tag.name),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (content.trim().isEmpty)
          Text(
            'No content',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: muted),
          )
        else
          NoteMarkdownBody(
            data: content,
            foreground: fg,
            onCheckboxToggle: _toggleCheckbox,
            onWikilinkTap: _openWikilink,
          ),
        if (backlinks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Backlinks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: 8),
          for (final n in backlinks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Symbols.link, color: muted),
              title: Text(
                n.title.isEmpty ? 'Untitled' : n.title,
                style: TextStyle(color: fg),
              ),
              onTap: n.uid == null
                  ? null
                  : () => context.push('/more/notes/${n.uid}'),
            ),
        ],
      ],
    );
  }

  Widget _buildEditor(BuildContext context, Color? fg) {
    return Column(
      children: [
        NoteEditorToolbar(
          onApply: _applyFormat,
          onInsertWikilink: () => _insertWikilink(),
          onOpenSlash: () => _runSlashCommand(),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: fg),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: fg?.withValues(alpha: 0.5)),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Symbols.folder, color: fg),
                  title: Text('Project', style: TextStyle(color: fg)),
                  subtitle: Text(
                    _projectName?.isNotEmpty == true
                        ? _projectName!
                        : 'No project',
                    style: TextStyle(color: fg?.withValues(alpha: 0.7)),
                  ),
                  trailing: Icon(Symbols.chevron_right, color: fg),
                  onTap: _saving ? null : _pickProject,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Symbols.label, color: fg),
                  title: Text('Tags', style: TextStyle(color: fg)),
                  subtitle: Text(
                    _tags.isEmpty
                        ? 'None'
                        : _tags.map((t) => t.name).join(', '),
                    style: TextStyle(color: fg?.withValues(alpha: 0.7)),
                  ),
                  trailing: Icon(Symbols.chevron_right, color: fg),
                  onTap: _saving ? null : _pickTags,
                ),
                const Divider(),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocus,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(color: fg),
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Write Markdown…  (/ commands, [[ note links)',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: fg?.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
