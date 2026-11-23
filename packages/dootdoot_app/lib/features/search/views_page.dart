import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../../core/widgets/shell_app_bar_actions.dart';
import '../tasks/task_actions.dart';

final viewsProvider = FutureProvider<List<TududiView>>((ref) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) return const [];
  return client.listViews();
});

class ViewsPage extends ConsumerWidget {
  const ViewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(viewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Views'),
        actions: const [ShellAppBarActions()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (views) {
          if (views.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No saved views yet.\nSearch → Save as View to create one.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          final sorted = [...views]
            ..sort((a, b) {
              if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(viewsProvider),
            child: ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final view = sorted[index];
                return ListTile(
                  leading: Icon(
                    view.isPinned ? Symbols.star : Symbols.bookmark,
                  ),
                  title: Text(view.name),
                  subtitle: Text(
                    [
                      if (view.searchQuery != null &&
                          view.searchQuery!.isNotEmpty)
                        '“${view.searchQuery}”',
                      if (view.filters.isNotEmpty) view.filters.join(', '),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Symbols.delete),
                    onPressed: () => _delete(context, ref, view),
                  ),
                  onTap: () {
                    final uid = view.uid;
                    if (uid != null) context.push('/more/views/$uid');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TududiView view,
  ) async {
    final uid = view.uid;
    if (uid == null) return;
    final ok = await confirmDelete(
      context,
      title: 'Delete view?',
      body: view.name,
    );
    if (!ok || !context.mounted) return;
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) throw TududiApiException(message: 'Not signed in');
      await client.deleteView(uid);
      ref.invalidate(viewsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('View deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
