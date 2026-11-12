import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'free_pro_controller.dart';
import 'pro_controller.dart';
import 'pro_unlock_sheet.dart';

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

/// Restores purchases and shows a snackbar with the outcome.
Future<bool> restoreProWithFeedback(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(proControllerProvider.notifier);
  try {
    final unlocked = await controller.restore();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unlocked
                ? 'DootDoot Pro restored'
                : 'No purchase found for this store account',
          ),
        ),
      );
    }
    return unlocked;
  } on ProPurchaseException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
    return false;
  }
}

/// Explains the store redeem flow, then opens it.
Future<void> redeemProWithFeedback(
  BuildContext context,
  WidgetRef ref,
) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Redeem promo code'),
      content: const Text(
        'Google Play opens a blank redeem screen — that is normal. '
        'Paste a Play promo code there.\n\n'
        'After it succeeds, return to DootDoot and tap Restore purchase.\n\n'
        'Promo codes are created in Play Console and often are not '
        'available while the app is only on testing tracks.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Open Play'),
        ),
      ],
    ),
  );
  if (proceed != true || !context.mounted) return;

  final controller = ref.read(proControllerProvider.notifier);
  final opened = await controller.redeemPromoCode();
  if (!context.mounted) return;
  if (!opened) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the store redeem screen'),
      ),
    );
  }
}

/// Shows the Pro unlock / status sheet. Returns `true` if unlock was started.
Future<bool> showProUnlockSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(proControllerProvider.notifier);
  final isPro = ref.read(proControllerProvider);
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => ProUnlockSheet(
      isPro: isPro,
      canPurchase: controller.canPurchase,
      onUnlock: () => Navigator.pop(sheetContext, true),
      onRestore: () async {
        if (sheetContext.mounted) Navigator.pop(sheetContext, false);
        if (context.mounted) await restoreProWithFeedback(context, ref);
      },
      onRedeem: () async {
        if (sheetContext.mounted) Navigator.pop(sheetContext, false);
        if (context.mounted) await redeemProWithFeedback(context, ref);
      },
      onDismiss: () => Navigator.pop(sheetContext, false),
    ),
  );
  if (result == true) {
    try {
      await controller.purchase();
    } on ProPurchaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return false;
    }
    return true;
  }
  return false;
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
    await showProUnlockSheet(context, ref);
    return ref.read(proControllerProvider);
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
  await showProUnlockSheet(context, ref);
  if (ref.read(proControllerProvider) && context.mounted) {
    context.push(route);
  }
}
