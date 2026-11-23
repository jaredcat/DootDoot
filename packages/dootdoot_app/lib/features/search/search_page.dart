import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../tasks/task_providers.dart';
import 'search_criteria.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    super.key,
    this.initial,
    this.viewUid,
    this.viewName,
    this.isPinned = false,
    this.onPinChanged,
  });

  final SearchCriteria? initial;
  final String? viewUid;
  final String? viewName;
  final bool isPinned;
  final VoidCallback? onPinChanged;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late SearchCriteria _criteria;
  bool _busy = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initial ?? const SearchCriteria();
    _controller = TextEditingController(text: _criteria.query);
    if (_criteria.query.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runSearch();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    setState(() {
      _busy = true;
      _error = null;
      _criteria = _criteria.copyWith(query: query);
    });
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) {
        setState(() => _error = 'Not signed in');
        return;
      }
      Map<String, dynamic> raw;
      try {
        raw = await client.search(
          query.isEmpty ? ' ' : query,
          priority: _criteria.priority,
          due: _criteria.due,
          tags: _criteria.tag == null ? null : [_criteria.tag!],
        );
        _offline = false;
      } catch (_) {
        raw = await _offlineFallback(query);
        _offline = true;
      }
      final filtered = filterSearchResult(raw, _criteria);
      setState(() {
        _result = filtered;
        _offline = filtered['offline'] == true || _offline;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _offlineFallback(String query) async {
    List<TududiTask> tasks = const [];
    List<TududiProject> projects = const [];
    List<TududiNote> notes = const [];
    try {
      tasks = await ref.read(tasksProvider(TaskListFilter.all).future);
    } catch (_) {}
    try {
      projects = await ref.read(projectsProvider.future);
    } catch (_) {}
    try {
      notes = await ref.read(notesProvider.future);
    } catch (_) {}
    if (tasks.isEmpty && projects.isEmpty && notes.isEmpty) {
      throw TududiApiException(
        message: 'Search unavailable offline (no cached data)',
      );
    }
    return offlineSearchResult(
      criteria: _criteria.copyWith(query: query),
      tasks: tasks,
      projects: projects,
      notes: notes,
    );
  }

  Future<void> _saveAsView() async {
    final nameController = TextEditingController(
      text: _controller.text.trim().isEmpty
          ? 'Saved search'
          : _controller.text.trim(),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save as View'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'View name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) throw TududiApiException(message: 'Not signed in');
      final created = await client.createView(
        _criteria.copyWith(query: _controller.text).toViewBody(name),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Saved view “${created.name}”')),
      );
      final uid = created.uid;
      if (uid != null && mounted) context.push('/more/views/$uid');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = (_result?['tasks'] as List?) ?? const [];
    final projects = (_result?['projects'] as List?) ?? const [];
    final notes = (_result?['notes'] as List?) ?? const [];

    final viewingSaved = widget.viewUid != null;

    return Scaffold(
      appBar: AppBar(
        title: viewingSaved
            ? Text(widget.viewName ?? 'View')
            : TextField(
                controller: _controller,
                autofocus: widget.initial == null,
                decoration: const InputDecoration(
                  hintText: 'Search tasks, projects, notes…',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(),
              ),
        actions: [
          if (viewingSaved)
            IconButton(
              tooltip: widget.isPinned ? 'Unpin' : 'Pin',
              icon: Icon(widget.isPinned ? Symbols.star : Symbols.star_outline),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final client = await ref.read(tududiClientProvider.future);
                  if (client == null) return;
                  await client.updateView(widget.viewUid!, {
                    'is_pinned': !widget.isPinned,
                  });
                  widget.onPinChanged?.call();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            )
          else ...[
            IconButton(
              tooltip: 'Views',
              onPressed: () => context.push('/more/views'),
              icon: const Icon(Symbols.bookmark),
            ),
            IconButton(
              tooltip: 'Save as View',
              onPressed: _busy ? null : _saveAsView,
              icon: const Icon(Symbols.bookmark_add),
            ),
          ],
          IconButton(
            onPressed: _busy ? null : _runSearch,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Symbols.search),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tasks'),
                  selected: _criteria.includeTasks,
                  onSelected: (v) => setState(() {
                    _criteria = _criteria.copyWith(includeTasks: v);
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Projects'),
                  selected: _criteria.includeProjects,
                  onSelected: (v) => setState(() {
                    _criteria = _criteria.copyWith(includeProjects: v);
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Notes'),
                  selected: _criteria.includeNotes,
                  onSelected: (v) => setState(() {
                    _criteria = _criteria.copyWith(includeNotes: v);
                  }),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(
                    _criteria.priority == null
                        ? 'Priority'
                        : 'Priority: ${_criteria.priority}',
                  ),
                  onPressed: () async {
                    final v = await _pickOption(
                      title: 'Priority',
                      options: const {
                        'Any': null,
                        'High': 'high',
                        'Medium': 'medium',
                        'Low': 'low',
                      },
                    );
                    if (v == null && !mounted) return;
                    setState(() {
                      _criteria = v == '__clear__'
                          ? _criteria.copyWith(clearPriority: true)
                          : _criteria.copyWith(priority: v);
                    });
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(
                    _criteria.due == null ? 'Due' : 'Due: ${_criteria.due}',
                  ),
                  onPressed: () async {
                    final v = await _pickOption(
                      title: 'Due',
                      options: const {
                        'Any': null,
                        'Today': 'today',
                        'This week': 'this_week',
                        'Overdue': 'overdue',
                        'No due date': 'no_due_date',
                      },
                    );
                    if (!mounted) return;
                    setState(() {
                      _criteria = v == null || v == '__clear__'
                          ? _criteria.copyWith(clearDue: true)
                          : _criteria.copyWith(due: v);
                    });
                  },
                ),
              ],
            ),
          ),
          if (_offline)
            ListTile(
              dense: true,
              leading: const Icon(Symbols.cloud_off),
              title: const Text('Showing cached results (offline)'),
              trailing: TextButton(
                onPressed: _runSearch,
                child: const Text('Retry'),
              ),
            ),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    children: [
                      if (tasks.isNotEmpty) ...[
                        const ListTile(title: Text('Tasks')),
                        ...tasks.whereType<Map>().map((t) {
                          final uid = t['uid']?.toString();
                          final name =
                              (t['name'] ?? t['original_name'] ?? 'Task')
                                  .toString();
                          return ListTile(
                            leading: const Icon(Symbols.check_circle),
                            title: Text(name),
                            onTap: uid == null
                                ? null
                                : () => context.push('/task/$uid'),
                          );
                        }),
                      ],
                      if (projects.isNotEmpty) ...[
                        const ListTile(title: Text('Projects')),
                        ...projects.whereType<Map>().map((p) {
                          final uid = p['uid']?.toString();
                          return ListTile(
                            leading: const Icon(Symbols.folder),
                            title: Text((p['name'] ?? 'Project').toString()),
                            onTap: uid == null
                                ? null
                                : () => context.push('/more/projects/$uid'),
                          );
                        }),
                      ],
                      if (notes.isNotEmpty) ...[
                        const ListTile(title: Text('Notes')),
                        ...notes.whereType<Map>().map((n) {
                          final uid = n['uid']?.toString();
                          return ListTile(
                            leading: const Icon(Symbols.notes),
                            title: Text(
                              (n['title'] ?? n['name'] ?? 'Note').toString(),
                            ),
                            onTap: uid == null
                                ? null
                                : () => context.push('/more/notes/$uid'),
                          );
                        }),
                      ],
                      if (_result != null &&
                          tasks.isEmpty &&
                          projects.isEmpty &&
                          notes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No matches')),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickOption({
    required String title,
    required Map<String, String?> options,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final entry in options.entries)
                ListTile(
                  title: Text(entry.key),
                  onTap: () =>
                      Navigator.of(context).pop(entry.value ?? '__clear__'),
                ),
            ],
          ),
        );
      },
    );
    return selected;
  }
}
