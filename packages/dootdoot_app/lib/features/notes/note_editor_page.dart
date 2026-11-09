import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../tasks/task_providers.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, required this.uid});

  final String? uid;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) return;
      final note = await client.getNote(widget.uid!);
      _titleController.text = note.title;
      _contentController.text = note.content ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) return;
      final body = {
        'title': _titleController.text.trim().isEmpty
            ? 'Untitled'
            : _titleController.text.trim(),
        'content': _contentController.text,
      };
      if (widget.uid == null) {
        await client.createNote(body);
      } else {
        await client.updateNote(widget.uid!, body);
      }
      ref.invalidate(notesProvider);
      if (mounted) Navigator.pop(context);
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
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uid == null ? 'New note' : 'Edit note'),
        actions: [
          IconButton(
            onPressed: _saving || _loading ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Write…',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
