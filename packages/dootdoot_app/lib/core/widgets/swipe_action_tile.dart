import 'package:material_ui/material_ui.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
}

/// Wraps a list row with a trailing (swipe-left) action pane.
class SwipeActionTile extends StatelessWidget {
  const SwipeActionTile({
    super.key,
    required this.actions,
    required this.child,
  });

  final List<SwipeAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return child;

    final scheme = Theme.of(context).colorScheme;
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: (0.22 * actions.length).clamp(0.25, 0.75),
        children: [
          for (final action in actions)
            CustomSlidableAction(
              onPressed: (_) => action.onPressed(),
              backgroundColor:
                  action.backgroundColor ?? scheme.secondaryContainer,
              foregroundColor:
                  action.foregroundColor ?? scheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}
