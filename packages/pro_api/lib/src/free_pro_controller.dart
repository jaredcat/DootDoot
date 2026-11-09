import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_cache_port.dart';
import 'pro_controller.dart';
import 'pro_nav.dart';

/// Community / public build: fully usable free app, no IAP, no Pro routes.
class FreeProController extends ProController {
  @override
  bool build() => false;

  @override
  bool get canPurchase => false;

  @override
  List<ProNavDestination> get destinations => const [];

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
  List<Widget> buildSettingsTiles(BuildContext context, WidgetRef ref) {
    return const [
      ListTile(
        leading: Icon(Icons.workspace_premium_outlined),
        title: Text('DootDoot Pro'),
        subtitle: Text(
          'Calendar, goals, habits, boards, offline cache, widgets, '
          'and unlimited accounts are available in the official App Store '
          'and Play Store build.',
        ),
        isThreeLine: true,
      ),
    ];
  }
}
