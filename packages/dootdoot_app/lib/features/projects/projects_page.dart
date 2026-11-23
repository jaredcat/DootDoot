import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../../core/widgets/shell_app_bar_actions.dart';
import '../tasks/task_providers.dart';
import 'project_edit_sheet.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createProject(context, ref),
        child: const Icon(Symbols.add),
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

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final result = await showProjectEditSheet(context, ref);
    if (result == null || !context.mounted) return;
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) throw TududiApiException(message: 'Not signed in');
      final created = await client.createProject(result);
      ref.invalidate(projectsProvider);
      if (!context.mounted) return;
      final uid = created.uid;
      if (uid != null) {
        context.push('/more/projects/$uid');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Project created')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
