import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../tasks/task_providers.dart';

/// Returns a create/update body map, or null if cancelled.
Future<Map<String, dynamic>?> showProjectEditSheet(
  BuildContext context,
  WidgetRef ref, {
  TududiProject? existing,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProjectEditSheet(existing: existing),
  );
}

class _ProjectEditSheet extends ConsumerStatefulWidget {
  const _ProjectEditSheet({this.existing});

  final TududiProject? existing;

  @override
  ConsumerState<_ProjectEditSheet> createState() => _ProjectEditSheetState();
}

class _ProjectEditSheetState extends ConsumerState<_ProjectEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  String? _state;
  int? _areaId;
  String? _areaUid;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _state = e?.state ?? ProjectState.notStarted;
    _areaId = e?.areaId;
    _areaUid = e?.areaUid;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickArea() async {
    final areas = await ref.read(areasProvider.future);
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
                title: const Text('No area'),
                trailing: _areaId == null && _areaUid == null
                    ? const Icon(Symbols.check)
                    : null,
                onTap: () => Navigator.of(context).pop('none'),
              ),
              for (final area in areas)
                ListTile(
                  title: Text(area.name),
                  trailing:
                      (area.uid != null && area.uid == _areaUid) ||
                          area.id == _areaId
                      ? const Icon(Symbols.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(area),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (selected == 'none') {
        _areaId = null;
        _areaUid = null;
      } else {
        final area = selected as TududiArea;
        _areaId = area.id;
        _areaUid = area.uid;
      }
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop({
      'name': name,
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'state': _state,
      'area_id': _areaId,
      'area_uid': _areaUid,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final areas =
        ref.watch(areasProvider).asData?.value ?? const <TududiArea>[];
    String areaLabel = 'No area';
    for (final a in areas) {
      if ((_areaUid != null && a.uid == _areaUid) || a.id == _areaId) {
        areaLabel = a.name;
        break;
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'New project' : 'Edit project',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _state,
              decoration: const InputDecoration(labelText: 'State'),
              items: const [
                DropdownMenuItem(
                  value: ProjectState.planned,
                  child: Text('Planned'),
                ),
                DropdownMenuItem(
                  value: ProjectState.notStarted,
                  child: Text('Not started'),
                ),
                DropdownMenuItem(
                  value: ProjectState.inProgress,
                  child: Text('In progress'),
                ),
                DropdownMenuItem(
                  value: ProjectState.waiting,
                  child: Text('Waiting'),
                ),
                DropdownMenuItem(value: ProjectState.done, child: Text('Done')),
                DropdownMenuItem(
                  value: ProjectState.cancelled,
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: (v) => setState(() => _state = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Area'),
              subtitle: Text(areaLabel),
              trailing: const Icon(Symbols.chevron_right),
              onTap: _pickArea,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
