import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nav_pin.dart';
import 'offline_cache_port.dart';
import 'pro_nav.dart';

/// Thrown by store [ProController.purchase] when billing cannot start.
class ProPurchaseException implements Exception {
  const ProPurchaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Open-core Pro surface. Free builds use [FreeProController]; the private
/// store app overrides [proControllerProvider] with the IAP-backed controller.
abstract class ProController extends Notifier<bool> {
  /// `null` means unlimited accounts. Free is capped at 1 until unlocked.
  int? get maxAccounts => state ? null : 1;

  /// Whether this binary can start an in-app purchase flow.
  bool get canPurchase;

  /// Whether offline task-list caching is active.
  bool get offlineEnabled => state;

  /// Store build exposes custom bottom-nav editing; free binary does not.
  bool get supportsCustomNav => false;

  /// Whether the shell should use [bottomNavPinsFor] instead of fixed tabs.
  bool get useCustomBottomNav => supportsCustomNav && state;

  /// Bumped when custom nav pins are saved so shell/router dependents rebuild.
  /// Free always returns `0`.
  int get navConfigRevision => 0;

  List<ProNavDestination> get destinations;

  List<ProMoreRoute> buildMoreRoutes();

  OfflineCachePort createOfflineCache(SharedPreferences prefs);

  Future<void> purchase();

  /// Restores store purchases. Returns `true` when Pro is unlocked afterward.
  /// Throws [ProPurchaseException] when billing is unavailable.
  Future<bool> restore();

  /// Pull entitlement from the store (e.g. after an out-of-app promo redeem).
  /// Free builds no-op; store builds query past purchases / restore.
  Future<void> syncPurchases() async {}

  /// Open the platform promo/offer code redeem flow. Free builds no-op.
  /// Returns `false` if the store UI could not be opened.
  Future<bool> redeemPromoCode() async => false;

  /// Extra Settings tiles (upsell, restore, offline, widgets, store blurb).
  List<Widget> buildSettingsTiles(BuildContext context, WidgetRef ref);

  /// Bottom-bar pins for [accountId]. Ignored unless [useCustomBottomNav].
  List<NavPin> bottomNavPinsFor(String accountId) => NavPin.defaults();

  /// Persist pins (Pro only). No-op on free.
  Future<void> saveBottomNavPins(String accountId, List<NavPin> pins) async {}

  /// Body for Pro-only slot kinds (calendar/goals/habits/boards). Free returns null.
  Widget? buildProNavSlot(NavPin pin) => null;
}
