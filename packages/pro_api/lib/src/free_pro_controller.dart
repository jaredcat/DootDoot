import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'nav_pin.dart';
import 'offline_cache_port.dart';
import 'pro_controller.dart';
import 'pro_nav.dart';
import 'pro_providers.dart';
import 'pro_widgets.dart';

/// Community / public build: fully usable free app, no IAP, no Pro screens.
///
/// Pro destinations still appear in More as locked rows with a Pro chip.
class FreeProController extends ProController {
  @override
  bool build() => false;

  @override
  bool get canPurchase => false;

  @override
  bool get supportsCustomNav => false;

  @override
  List<ProNavDestination> get destinations => ProDestinations.all;

  @override
  List<ProMoreRoute> buildMoreRoutes() => const [];

  @override
  OfflineCachePort createOfflineCache(SharedPreferences prefs) {
    return const NoOpOfflineCache();
  }

  @override
  Future<void> purchase() async {}

  @override
  Future<bool> restore() async => false;

  @override
  List<NavPin> bottomNavPinsFor(String accountId) => NavPin.defaults();

  @override
  List<Widget> buildSettingsTiles(BuildContext context, WidgetRef ref) {
    return [
      ListTile(
        leading: const Icon(Symbols.workspace_premium),
        title: const Text('DootDoot Pro'),
        subtitle: const Text(
          'Calendar, goals, habits, boards, offline sync, widgets, '
          'custom bottom navigation, and unlimited accounts are available '
          'with DootDoot Pro on the App Store and Google Play.',
        ),
        trailing: const ProBadge(),
        isThreeLine: true,
        onTap: () => showProUnlockSheet(context, ref),
      ),
      const ListTile(
        leading: Icon(Symbols.space_dashboard),
        title: Text('Navigation'),
        subtitle: Text('Pro enhancement'),
        trailing: ProBadge(),
        enabled: false,
      ),
    ];
  }
}
