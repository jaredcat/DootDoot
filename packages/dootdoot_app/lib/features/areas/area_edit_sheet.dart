import 'package:material_ui/material_ui.dart';
import 'package:tududi_api/tududi_api.dart';

/// Returns a create/update body map, or null if cancelled.
Future<Map<String, dynamic>?> showAreaEditSheet(
  BuildContext context, {
  TududiArea? existing,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AreaEditSheet(existing: existing),
  );
}

class _AreaEditSheet extends StatefulWidget {
  const _AreaEditSheet({this.existing});

  final TududiArea? existing;

  @override
  State<_AreaEditSheet> createState() => _AreaEditSheetState();
}

class _AreaEditSheetState extends State<_AreaEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop({
      'name': name,
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'New area' : 'Edit area',
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(widget.existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}
