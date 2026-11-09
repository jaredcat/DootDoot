import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';

import '../tasks/task_providers.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
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
                  trailing: const Icon(Icons.chevron_right),
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
