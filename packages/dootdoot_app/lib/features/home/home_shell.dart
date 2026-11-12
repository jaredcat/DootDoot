import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../../core/widgets/quick_add_sheet.dart';
import '../../core/widgets/shell_app_bar_actions.dart';
import '../tasks/task_list_view.dart';
import 'more_page.dart';
import 'nav_slot_page.dart';

/// Max pin slots in the Pro custom shell (More is a separate fixed branch).
const kCustomNavSlotCount = NavPin.maxPins;

/// Live bottom-nav pins. [setPins] updates the bar immediately, then persists.
final bottomNavPinsProvider =
    NotifierProvider<BottomNavPinsNotifier, List<NavPin>>(
  BottomNavPinsNotifier.new,
);

class BottomNavPinsNotifier extends Notifier<List<NavPin>> {
  @override
  List<NavPin> build() {
    ref.watch(proControllerProvider);
    final controller = ref.read(proControllerProvider.notifier);
    if (!controller.useCustomBottomNav) {
      return NavPin.defaults();
    }
    final accountId = ref.watch(activeAccountIdProvider) ?? 'default';
    return List.of(controller.bottomNavPinsFor(accountId));
  }

  /// Apply pins to the shell right away, then persist (Pro).
  Future<void> setPins(List<NavPin> pins) async {
    final clipped = pins.take(NavPin.maxPins).toList();
    final next = clipped.isEmpty ? NavPin.defaults() : clipped;
    state = List.of(next);

    final controller = ref.read(proControllerProvider.notifier);
    if (!controller.useCustomBottomNav) return;

    final accountId = ref.read(activeAccountIdProvider) ?? 'default';
    await controller.saveBottomNavPins(accountId, next);
  }
}

final useCustomBottomNavProvider = Provider<bool>((ref) {
  ref.watch(proControllerProvider);
  return ref.watch(proControllerProvider.notifier).useCustomBottomNav;
});

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(bottomNavPinsProvider);
    final useCustom = ref.watch(useCustomBottomNavProvider);
    final shellIndex = navigationShell.currentIndex;

    // Custom mode: branches 0..4 are pin slots, branch 5 is More.
    final moreBranchIndex = useCustom ? kCustomNavSlotCount : 3;
    final isMore = shellIndex >= moreBranchIndex ||
        (useCustom && shellIndex >= pins.length);
    final currentPin =
        (!isMore && shellIndex < pins.length) ? pins[shellIndex] : null;
    final showFab = currentPin?.isTaskList ?? false;
    final shellOwnsAppBar =
        isMore || currentPin == null || currentPin.isTaskList;

    final selectedIndex = useCustom
        ? (isMore ? pins.length : shellIndex.clamp(0, pins.length - 1))
        : shellIndex;

    return Scaffold(
      appBar: shellOwnsAppBar
          ? AppBar(
              title: Text(
                isMore
                    ? 'More'
                    : (currentPin?.label ?? _legacyTitleFor(shellIndex)),
              ),
              actions: const [
                ShellAppBarActions(showSearch: true),
              ],
            )
          : null,
      body: navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => showQuickAddSheet(context),
              child: const Icon(Symbols.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (useCustom) {
            if (i >= pins.length) {
              navigationShell.goBranch(moreBranchIndex);
            } else {
              navigationShell.goBranch(i);
            }
          } else {
            navigationShell.goBranch(i);
          }
        },
        destinations: [
          if (useCustom)
            ...pins.map(
              (pin) => NavigationDestination(
                icon: Icon(pin.icon),
                selectedIcon: Icon(pin.selectedIcon, fill: 1),
                label: pin.label,
              ),
            )
          else ...[
            const NavigationDestination(
              icon: Icon(Symbols.wb_sunny),
              selectedIcon: Icon(Symbols.wb_sunny, fill: 1),
              label: 'Today',
            ),
            const NavigationDestination(
              icon: Icon(Symbols.calendar_view_week),
              selectedIcon: Icon(Symbols.calendar_view_week, fill: 1),
              label: 'Upcoming',
            ),
            const NavigationDestination(
              icon: Icon(Symbols.inbox),
              selectedIcon: Icon(Symbols.inbox, fill: 1),
              label: 'Inbox',
            ),
          ],
          const NavigationDestination(
            icon: Icon(Symbols.grid_view),
            selectedIcon: Icon(Symbols.grid_view, fill: 1),
            label: 'More',
          ),
        ],
      ),
    );
  }

  String _legacyTitleFor(int index) {
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

/// Slot body that reads the live pin at [slotIndex] (survives pin edits).
class NavPinTab extends ConsumerWidget {
  const NavPinTab({super.key, required this.slotIndex});

  final int slotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(bottomNavPinsProvider);
    if (slotIndex >= pins.length) {
      return const SizedBox.shrink();
    }
    return NavSlotPage(pin: pins[slotIndex]);
  }
}
