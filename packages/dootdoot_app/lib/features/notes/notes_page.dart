import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/edit_history/edit_commands.dart';
import '../../core/edit_history/edit_history.dart';
import '../../core/edit_history/edit_overlay.dart';
import '../../core/offline/offline_write_coordinator.dart';
import '../../core/widgets/shell_app_bar_actions.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notesProvider);
    final overlay = ref.watch(editOverlayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: const [ShellAppBarActions()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        child: const Icon(Symbols.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (rawNotes) {
          final notes = mergeNoteOverlay(rawNotes, overlay.notes);
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notesProvider),
            child: ListView.separated(
              itemCount: notes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final note = notes[index];
                final tile = ListTile(
                  title: Text(note.title.isEmpty ? 'Untitled' : note.title),
                  subtitle: note.content == null || note.content!.isEmpty
                      ? null
                      : Text(
                          note.content!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () {
                    final uid = note.uid;
                    if (uid != null) context.push('/more/notes/$uid');
                  },
                );
                return SwipeActionTile(
                  actions: [
                    SwipeAction(
                      label: 'Delete',
                      icon: Symbols.delete,
                      backgroundColor: DootColors.coral,
                      foregroundColor: Colors.white,
                      onPressed: () => _deleteNote(context, ref, note),
                    ),
                  ],
                  child: tile,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    TududiNote note,
  ) async {
    final uid = note.uid;
    if (uid == null) return;
    final ok = await confirmDelete(
      context,
      title: 'Delete note?',
      body: note.title.isEmpty ? 'Untitled' : note.title,
    );
    if (!ok || !context.mounted) return;
    try {
      final result = await ref.read(offlineWriteCoordinatorProvider).deleteNote(
            uid,
            current: note,
          );
      ref.read(editHistoryProvider.notifier).push(NoteDeleteCommand(note));
      ref.invalidate(notesProvider);
      if (!context.mounted) return;
      final msg = offlineQueuedMessage(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Deleted')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
