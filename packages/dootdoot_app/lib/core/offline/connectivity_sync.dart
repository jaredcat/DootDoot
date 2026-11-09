import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_write_coordinator.dart';

/// Listens for network regain and drains the Pro offline outbox.
class ConnectivitySync {
  ConnectivitySync(this._ref);

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  var _wasOffline = false;

  void start() {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline) {
        _wasOffline = true;
        _ref.read(syncStatusProvider.notifier).markOffline();
        return;
      }
      if (_wasOffline) {
        _wasOffline = false;
        _ref.read(syncStatusProvider.notifier).markOnline();
        _ref.read(offlineWriteCoordinatorProvider).drain();
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

final connectivitySyncProvider = Provider<ConnectivitySync>((ref) {
  final sync = ConnectivitySync(ref);
  sync.start();
  ref.onDispose(sync.dispose);
  return sync;
});
