import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/widgets/shell_app_bar_actions.dart';
import '../tasks/task_providers.dart';

class AreasPage extends ConsumerWidget {
  const AreasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(areasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Areas'),
        actions: const [ShellAppBarActions()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (areas) {
          if (areas.isEmpty) {
            return const Center(child: Text('No areas yet'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(areasProvider),
            child: ListView.separated(
              itemCount: areas.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final area = areas[index];
                return ListTile(
                  leading: const Icon(Symbols.layers),
                  title: Text(area.name),
                  subtitle:
                      area.description != null && area.description!.isNotEmpty
                      ? Text(area.description!)
                      : null,
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () {
                    final uid = area.uid;
                    if (uid != null) {
                      context.push('/more/areas/$uid');
                    }
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
