import 'core/sync/background_sync.dart';

/// Initializes local notifications + background sync before [runApp].
Future<void> initializeDootdootNotifications() async {
  final service = BackgroundSync.notificationService;
  // Preferences are attached again once SharedPreferences is available via
  // Riverpod; initialize the plugin early so permission APIs work.
  await service.initialize();
  await BackgroundSync.initializeWorker();
}
