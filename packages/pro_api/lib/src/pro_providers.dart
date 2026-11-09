import 'package:flutter/material.dart';
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
        await controller.restore();
        if (sheetContext.mounted) Navigator.pop(sheetContext, false);
      },
      onRedeem: () async {
        await controller.redeemPromoCode();
        if (sheetContext.mounted) Navigator.pop(sheetContext, false);
      },
      onDismiss: () => Navigator.pop(sheetContext, false),
    ),
  );
  if (result == true) {
    await controller.purchase();
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
