import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/edit_history/edit_commands.dart';
import '../../core/edit_history/edit_history.dart';
import '../../core/offline/offline_write_coordinator.dart';
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
  TududiNote? _current;

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
      if (client != null) {
        try {
          final note = await client.getNote(widget.uid!);
          _current = note;
          _titleController.text = note.title;
          _contentController.text = note.content ?? '';
          return;
        } catch (_) {
          // Fall through to cache when offline.
        }
      }
      final account = ref.read(activeAccountProvider);
      final isPro = ref.read(proControllerProvider);
      if (account != null && isPro) {
        final cache = ref.read(offlineCacheProvider);
        final raw = await cache.getJson(account.id, 'notes');
        if (raw is List) {
          for (final item in raw.whereType<Map>()) {
            final note =
                TududiNote.fromJson(Map<String, dynamic>.from(item));
            if (note.uid == widget.uid) {
              _current = note;
              _titleController.text = note.title;
              _contentController.text = note.content ?? '';
              break;
            }
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'title': _titleController.text.trim().isEmpty
            ? 'Untitled'
            : _titleController.text.trim(),
        'content': _contentController.text,
      };
      final coordinator = ref.read(offlineWriteCoordinatorProvider);
      final OfflineMutationResult<TududiNote> result;
      if (widget.uid == null) {
        result = await coordinator.createNote(body);
        final created = result.value;
        if (created.uid != null) {
          ref.read(editHistoryProvider.notifier).push(NoteCreateCommand(created));
        }
      } else {
        final before = _current;
        result = await coordinator.updateNote(
          widget.uid!,
          body,
          current: before,
        );
        if (before != null) {
          ref.read(editHistoryProvider.notifier).push(
                NoteUpdateCommand(before: before, after: result.value),
              );
        }
      }
      ref.invalidate(notesProvider);
      if (!mounted) return;
      final msg = offlineQueuedMessage(result);
      if (msg != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      Navigator.pop(context);
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
                : const Icon(Symbols.check),
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
