import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../tasks/today_section_prefs.dart';

/// Tududi-parity toggles for Today page sections (Planned is always shown).
class TodaySettingsPage extends ConsumerWidget {
  const TodaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(todaySectionVisibilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        children: [
          const ListTile(
            subtitle: Text(
              'Choose which sections appear on Today. Planned is always shown.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Symbols.warning_amber),
            title: const Text('Overdue'),
            subtitle: const Text('Past-due tasks that need attention'),
            value: visibility.showOverdue,
            onChanged: (v) => ref
                .read(todaySectionVisibilityProvider.notifier)
                .update(visibility.copyWith(showOverdue: v)),
          ),
          const ListTile(
            leading: Icon(Symbols.play_circle),
            title: Text('Planned'),
            subtitle: Text('In progress, planned, and waiting — always shown'),
          ),
          SwitchListTile(
            secondary: const Icon(Symbols.lightbulb),
            title: const Text('Suggested'),
            subtitle: const Text('Recommended next tasks'),
            value: visibility.showSuggested,
            onChanged: (v) => ref
                .read(todaySectionVisibilityProvider.notifier)
                .update(visibility.copyWith(showSuggested: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Symbols.check_circle),
            title: const Text('Completed'),
            subtitle: const Text('Tasks finished today'),
            value: visibility.showCompleted,
            onChanged: (v) => ref
                .read(todaySectionVisibilityProvider.notifier)
                .update(visibility.copyWith(showCompleted: v)),
          ),
        ],
      ),
    );
  }
}
