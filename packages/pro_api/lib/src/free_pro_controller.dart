import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nav_pin.dart';
import 'offline_cache_port.dart';
import 'pro_controller.dart';
import 'pro_nav.dart';
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
  Future<void> restore() async {}

  @override
  List<NavPin> bottomNavPinsFor(String accountId) => NavPin.defaults();

  @override
  List<Widget> buildSettingsTiles(BuildContext context, WidgetRef ref) {
    return const [
      ListTile(
        leading: Icon(Icons.workspace_premium_outlined),
        title: Text('DootDoot Pro'),
        subtitle: Text(
          'Calendar, goals, habits, boards, offline sync, widgets, '
          'custom bottom navigation, and unlimited accounts are available '
          'with DootDoot Pro on the App Store and Google Play.',
        ),
        trailing: ProBadge(),
        isThreeLine: true,
      ),
      ListTile(
        leading: Icon(Icons.space_dashboard_outlined),
        title: Text('Navigation'),
        subtitle: Text('Pro enhancement'),
        trailing: ProBadge(),
        enabled: false,
      ),
    ];
  }
}
