import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tududi_api/tududi_api.dart';

/// Edit task tags. Returns the selected tag names (empty list clears).
Future<List<String>?> showTagPicker(
  BuildContext context, {
  required List<TududiTag> selected,
  required List<TududiTag> allTags,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TagPickerSheet(
      initial: selected.map((t) => t.name).toList(),
      suggestions: allTags.map((t) => t.name).toList(),
    ),
  );
}

class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({required this.initial, required this.suggestions});

  final List<String> initial;
  final List<String> suggestions;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  static const _system = ['today', 'someday', 'urgent'];

  late final Set<String> _selected;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selected = {
      for (final name in widget.initial)
        if (name.trim().isNotEmpty) name.trim(),
    };
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    setState(() {
      if (_selected.any((s) => s.toLowerCase() == name.toLowerCase())) {
        _selected.removeWhere((s) => s.toLowerCase() == name.toLowerCase());
      } else {
        _selected.add(name);
      }
    });
  }

  void _addFromField() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    _toggle(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final known = <String>{
      ..._system,
      ...widget.suggestions,
      ..._selected,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tags', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'today pins to Today · someday parks for later · urgent marks Eisenhower',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in known)
                    FilterChip(
                      label: Text(name),
                      selected: _selected.any(
                        (s) => s.toLowerCase() == name.toLowerCase(),
                      ),
                      onSelected: (_) => _toggle(name),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Add a tag…',
                  suffixIcon: IconButton(
                    icon: const Icon(Symbols.add),
                    onPressed: _addFromField,
                  ),
                ),
                onSubmitted: (_) => _addFromField(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_selected.toList()..sort()),
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
