import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../edit_history/edit_history.dart';
import '../offline/sync_status_button.dart';
import '../providers.dart';
import 'account_switcher_sheet.dart';

/// Shared AppBar trailing cluster: sync, undo/redo, account avatar, optional search.
class ShellAppBarActions extends ConsumerWidget {
  const ShellAppBarActions({
    super.key,
    this.showSearch = false,
    this.extra = const [],
  });

  final bool showSearch;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    final history = ref.watch(editHistoryProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SyncStatusButton(),
        IconButton(
          tooltip: 'Undo',
          onPressed: history.canUndo
              ? () {
                  final label =
                      ref.read(editHistoryProvider.notifier).undo();
                  if (label != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Undid $label')),
                    );
                  }
                }
              : null,
          icon: const Icon(Symbols.undo),
        ),
        IconButton(
          tooltip: 'Redo',
          onPressed: history.canRedo
              ? () {
                  final label =
                      ref.read(editHistoryProvider.notifier).redo();
                  if (label != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Redid $label')),
                    );
                  }
                }
              : null,
          icon: const Icon(Symbols.redo),
        ),
        if (account != null)
          IconButton(
            tooltip: account.label,
            onPressed: () => showAccountSwitcher(context),
            icon: CircleAvatar(
              radius: 14,
              child: Text(
                account.label.isNotEmpty
                    ? account.label.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        if (showSearch)
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push('/more/search'),
            icon: const Icon(Symbols.search),
          ),
        ...extra,
      ],
    );
  }
}
