import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../edit_history/edit_commands.dart';
import '../edit_history/edit_history.dart';
import '../offline/offline_write_coordinator.dart';
import '../../features/tasks/tag_picker.dart';
import '../../features/tasks/task_providers.dart';

Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const QuickAddSheet(),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _dueDate;
  int? _projectId;
  String? _projectUid;
  String? _projectName;
  List<String> _tagNames = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDue() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('None'),
                onTap: () => Navigator.of(context).pop('none'),
              ),
              ListTile(
                title: const Text('Today'),
                onTap: () => Navigator.of(context).pop('today'),
              ),
              ListTile(
                title: const Text('Pick date…'),
                onTap: () => Navigator.of(context).pop('pick'),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    if (choice == 'none') {
      setState(() => _dueDate = null);
      return;
    }
    if (choice == 'today') {
      setState(() => _dueDate = _todayIso());
      return;
    }
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDate =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickProject() async {
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
                title: const Text('Inbox (no project)'),
                trailing: _projectId == null && _projectUid == null
                    ? const Icon(Symbols.check)
                    : null,
                onTap: () => Navigator.of(context).pop('inbox'),
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
      if (selected == 'inbox') {
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

  Future<void> _pickTags() async {
    final all = await ref.read(tagsProvider.future);
    if (!mounted) return;
    final names = await showTagPicker(
      context,
      selected: [
        for (var i = 0; i < _tagNames.length; i++)
          TududiTag(id: i, name: _tagNames[i]),
      ],
      allTags: all,
    );
    if (names == null || !mounted) return;
    setState(() => _tagNames = names);
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final body = <String, dynamic>{
        'name': name,
        if (_dueDate != null) 'due_date': _dueDate,
        if (_projectId != null) 'project_id': _projectId,
        if (_projectUid != null) 'project_uid': _projectUid,
        if (_tagNames.isNotEmpty) 'tags': _tagNames,
      };
      final result = await ref
          .read(offlineWriteCoordinatorProvider)
          .createTask(body);
      final created = result.value;
      if (created.uid != null) {
        ref.read(editHistoryProvider.notifier).push(TaskCreateCommand(created));
      }
      ref.invalidate(tasksProvider(TaskListFilter.today));
      ref.invalidate(tasksProvider(TaskListFilter.inbox));
      ref.invalidate(tasksProvider(TaskListFilter.all));
      if (!mounted) return;
      final offlineMsg = offlineQueuedMessage(result);
      if (offlineMsg != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(offlineMsg)));
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick add', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: 'What needs doing?'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Symbols.event),
              title: const Text('Due'),
              subtitle: Text(_dueDate ?? 'None'),
              onTap: _busy ? null : _pickDue,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Symbols.folder),
              title: const Text('Project'),
              subtitle: Text(_projectName ?? 'Inbox'),
              onTap: _busy ? null : _pickProject,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Symbols.label),
              title: const Text('Tags'),
              subtitle: Text(_tagNames.isEmpty ? 'None' : _tagNames.join(', ')),
              onTap: _busy ? null : _pickTags,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add task'),
            ),
          ],
        ),
      ),
    );
  }
}
