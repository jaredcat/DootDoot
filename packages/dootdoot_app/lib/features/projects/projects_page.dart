import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/widgets/shell_app_bar_actions.dart';
import '../tasks/task_providers.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: const [ShellAppBarActions()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(child: Text('No projects yet'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final project = projects[index];
                final stateLabel = ProjectState.label(project.state);
                return ListTile(
                  title: Text(project.name),
                  subtitle: stateLabel.isNotEmpty ? Text(stateLabel) : null,
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () {
                    final uid = project.uid;
                    if (uid != null) {
                      context.push('/more/projects/$uid');
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
