import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../tasks/task_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (notes) {
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
                return ListTile(
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
              },
            ),
          );
        },
      ),
    );
  }
}
