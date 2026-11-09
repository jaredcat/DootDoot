import 'package:dootdoot_app/core/sync/background_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('register and cancel are safe without a native plugin', () async {
    await expectLater(BackgroundSync.register(), completes);
    await expectLater(BackgroundSync.cancel(), completes);
  });

  test('unique task id matches iOS BGTaskScheduler identifier', () {
    expect(BackgroundSync.uniqueName, 'com.codekitties.dootdoot.sync');
  });
}
