import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/account_switcher_sheet.dart';
import '../../core/widgets/quick_add_sheet.dart';
import '../tasks/task_list_view.dart';
import 'more_page.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(navigationShell.currentIndex)),
        actions: [
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
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push('/more/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex < 3
          ? FloatingActionButton(
              onPressed: () => showQuickAddSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Upcoming',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'More',
          ),
        ],
      ),
    );
  }

  String _titleFor(int index) {
    switch (index) {
      case 1:
        return 'Upcoming';
      case 2:
        return 'Inbox';
      case 3:
        return 'More';
      case 0:
      default:
        return 'Today';
    }
  }
}

/// Tab bodies used by the router branches.
class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskListView(filter: TaskListFilter.today);
  }
}

class UpcomingTab extends StatelessWidget {
  const UpcomingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskListView(filter: TaskListFilter.upcoming);
  }
}

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskListView(filter: TaskListFilter.inbox);
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MorePage();
  }
}
