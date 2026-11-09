import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_cache_port.dart';
import 'pro_nav.dart';

/// Open-core Pro surface. Free builds use [FreeProController]; the private
/// store app overrides [proControllerProvider] with the IAP-backed controller.
abstract class ProController extends Notifier<bool> {
  /// `null` means unlimited accounts. Free is capped at 1 until unlocked.
  int? get maxAccounts => state ? null : 1;

  /// Whether this binary can start an in-app purchase flow.
  bool get canPurchase;

  /// Whether offline task-list caching is active.
  bool get offlineEnabled => state;

  List<ProNavDestination> get destinations;

  List<ProMoreRoute> buildMoreRoutes();

  OfflineCachePort createOfflineCache(SharedPreferences prefs);

  Future<void> purchase();

  Future<void> restore();

  /// Extra Settings tiles (upsell, restore, offline, widgets, store blurb).
  List<Widget> buildSettingsTiles(BuildContext context, WidgetRef ref);
}
