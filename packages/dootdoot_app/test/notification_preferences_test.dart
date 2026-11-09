import 'package:dootdoot_app/core/notifications/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults and recommended enable', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = NotificationPreferences(
      await SharedPreferences.getInstance(),
    );

    expect(prefs.permissionAsked, isFalse);
    expect(prefs.taskDueEnabled, isFalse);
    expect(prefs.dailyDigestEnabled, isFalse);
    expect(prefs.digestHour, 8);

    await prefs.setPermissionAsked(true);
    await prefs.enableRecommendedDefaults();
    await prefs.setDigestHour(7);

    expect(prefs.permissionAsked, isTrue);
    expect(prefs.taskDueEnabled, isTrue);
    expect(prefs.dailyDigestEnabled, isTrue);
    expect(prefs.digestHour, 7);
  });

  test('digest hour is clamped', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = NotificationPreferences(
      await SharedPreferences.getInstance(),
    );

    await prefs.setDigestHour(30);
    expect(prefs.digestHour, 23);
    await prefs.setDigestHour(-2);
    expect(prefs.digestHour, 0);
  });
}
