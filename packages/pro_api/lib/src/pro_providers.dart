import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'free_pro_controller.dart';
import 'pro_controller.dart';

final proControllerProvider =
    NotifierProvider<ProController, bool>(FreeProController.new);

/// Returns `true` when another account may be added under the current Pro cap.
bool canAddAccount({
  required int accountCount,
  required ProController controller,
}) {
  final max = controller.maxAccounts;
  if (max == null) return true;
  return accountCount < max;
}

/// Gates adding an account: upsell when the store build can purchase, otherwise
/// a snackbar explaining the free limit.
Future<bool> ensureCanAddAccount(
  BuildContext context,
  WidgetRef ref, {
  required int accountCount,
}) async {
  final controller = ref.read(proControllerProvider.notifier);
  if (canAddAccount(accountCount: accountCount, controller: controller)) {
    return true;
  }

  if (controller.canPurchase) {
    final unlock = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _AccountLimitUpsellSheet(),
    );
    if (unlock == true) {
      await controller.purchase();
      if (ref.read(proControllerProvider)) return true;
    }
    return false;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Free includes one account. Unlimited accounts are available '
          'with DootDoot Pro.',
        ),
      ),
    );
  }
  return false;
}

/// Opens a Pro destination, purchasing first when locked in the store build.
Future<void> openProFeature(
  BuildContext context,
  WidgetRef ref, {
  required String route,
}) async {
  final isPro = ref.read(proControllerProvider);
  final controller = ref.read(proControllerProvider.notifier);
  if (isPro) {
    context.push(route);
    return;
  }
  if (!controller.canPurchase) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This enhancement is available with DootDoot Pro.',
          ),
        ),
      );
    }
    return;
  }
  final unlock = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _ProUpsellSheet(),
  );
  if (unlock == true && context.mounted) {
    await controller.purchase();
    if (ref.read(proControllerProvider) && context.mounted) {
      context.push(route);
    }
  }
}

class _ProUpsellSheet extends ConsumerWidget {
  const _ProUpsellSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Unlock DootDoot Pro',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'One-time purchase for calendar, goals, habits, boards, offline '
            'cache, widgets, and unlimited accounts. Core tasks stay free '
            'forever.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock Pro'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(proControllerProvider.notifier).restore();
              if (context.mounted) Navigator.pop(context, false);
            },
            child: const Text('Restore purchase'),
          ),
        ],
      ),
    );
  }
}

class _AccountLimitUpsellSheet extends ConsumerWidget {
  const _AccountLimitUpsellSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Unlimited accounts with Pro',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The free tier includes one account. Unlock Pro for unlimited '
            'accounts plus calendar, goals, habits, boards, and offline cache.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlock Pro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
