import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';

import '../accounts/accounts_page.dart';
import '../areas/area_detail_page.dart';
import '../areas/areas_page.dart';
import '../notes/note_editor_page.dart';
import '../notes/notes_page.dart';
import '../projects/project_detail_page.dart';
import '../projects/projects_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import '../tasks/task_list_view.dart';

/// Renders the body for one customizable bottom-nav pin.
class NavSlotPage extends ConsumerWidget {
  const NavSlotPage({super.key, required this.pin});

  final NavPin pin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(proControllerProvider.notifier);
    final proBody = controller.buildProNavSlot(pin);
    if (proBody != null) return proBody;

    switch (pin.kind) {
      case NavPinKind.today:
        return const TaskListView(filter: TaskListFilter.today);
      case NavPinKind.upcoming:
        return const TaskListView(filter: TaskListFilter.upcoming);
      case NavPinKind.inbox:
        return const TaskListView(filter: TaskListFilter.inbox);
      case NavPinKind.someday:
        return const TaskListView(filter: TaskListFilter.someday);
      case NavPinKind.projects:
        return const ProjectsPage();
      case NavPinKind.areas:
        return const AreasPage();
      case NavPinKind.notes:
        return const NotesPage();
      case NavPinKind.search:
        return const SearchPage();
      case NavPinKind.settings:
        return const SettingsPage();
      case NavPinKind.accounts:
        return const AccountsPage();
      case NavPinKind.project:
        final uid = pin.entityUid;
        if (uid == null) {
          return const Center(child: Text('Missing project'));
        }
        return ProjectDetailPage(uid: uid);
      case NavPinKind.area:
        final uid = pin.entityUid;
        if (uid == null) {
          return const Center(child: Text('Missing area'));
        }
        return AreaDetailPage(uid: uid);
      case NavPinKind.note:
        final uid = pin.entityUid;
        if (uid == null) {
          return const Center(child: Text('Missing note'));
        }
        return NoteEditorPage(uid: uid);
      case NavPinKind.calendar:
      case NavPinKind.goals:
      case NavPinKind.habits:
      case NavPinKind.boards:
        return const Center(child: Text('Pro feature unavailable'));
    }
  }
}
