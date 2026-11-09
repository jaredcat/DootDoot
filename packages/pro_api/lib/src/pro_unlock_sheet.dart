import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'pro_widgets.dart';

/// Paywall / unlock surface for the store build (and status when already Pro).
class ProUnlockSheet extends StatelessWidget {
  const ProUnlockSheet({
    super.key,
    required this.isPro,
    required this.canPurchase,
    required this.onUnlock,
    required this.onRestore,
    required this.onRedeem,
    required this.onDismiss,
  });

  final bool isPro;
  final bool canPurchase;
  final VoidCallback onUnlock;
  final VoidCallback onRestore;
  final VoidCallback onRedeem;
  final VoidCallback onDismiss;

  static const features = <(IconData, String)>[
    (Symbols.calendar_month, 'Calendar'),
    (Symbols.flag, 'Goals'),
    (Symbols.loop, 'Habits'),
    (Symbols.view_kanban, 'Boards'),
    (Symbols.cloud_off, 'Automatic offline sync'),
    (Symbols.space_dashboard, 'Custom bottom navigation'),
    (Symbols.switch_account, 'Unlimited accounts'),
    (Symbols.widgets, 'Widgets (as they ship)'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.workspace_premium,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPro ? 'DootDoot Pro' : 'Unlock DootDoot Pro',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (isPro) const ProBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPro
                  ? 'Thanks for supporting the app. These enhancements are '
                      'unlocked on this device.'
                  : 'One-time unlock. Core tasks stay free forever.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final (icon, label) in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (!isPro && canPurchase) ...[
              FilledButton(
                onPressed: onUnlock,
                child: const Text('Unlock Pro'),
              ),
              TextButton(
                onPressed: onRestore,
                child: const Text('Restore purchase'),
              ),
              TextButton(
                onPressed: onRedeem,
                child: const Text('Redeem code'),
              ),
            ] else if (isPro && canPurchase) ...[
              FilledButton(
                onPressed: onDismiss,
                child: const Text('Done'),
              ),
              TextButton(
                onPressed: onRestore,
                child: const Text('Restore purchase'),
              ),
            ] else ...[
              Text(
                'DootDoot Pro is available on the App Store and Google Play.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onDismiss,
                child: const Text('Got it'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
