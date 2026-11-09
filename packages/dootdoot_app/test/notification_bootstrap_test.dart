import 'package:dootdoot_app/core/accounts/account_profile.dart';
import 'package:dootdoot_app/core/notifications/notification_bootstrap.dart';
import 'package:dootdoot_app/core/notifications/notification_preferences.dart';
import 'package:dootdoot_app/core/notifications/notification_providers.dart';
import 'package:dootdoot_app/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleAccount = AccountProfile(
    id: 'a1',
    baseUrl: 'https://app.tududi.com',
    label: 'Test',
    email: 'test@example.com',
    authKind: AccountAuthKind.apiToken,
    createdAt: DateTime(2026, 1, 1),
    lastUsedAt: DateTime(2026, 1, 1),
  );

  Future<void> pumpBootstrap(
    WidgetTester tester, {
    required bool permissionAsked,
    AccountProfile? account,
  }) async {
    SharedPreferences.setMockInitialValues({
      NotificationPreferences.askedKey: permissionAsked,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPreferences.askedKey, permissionAsked);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (account != null) activeAccountProvider.overrideWithValue(account),
          // Avoid kicking off task fetches / secure-storage reads in this UX test.
          notificationScheduleProvider.overrideWith((ref) async {}),
        ],
        child: const MaterialApp(
          home: NotificationBootstrap(child: Scaffold(body: Text('home'))),
        ),
      ),
    );
    await tester.pump();
    // Post-frame prompt + async register() + modal route.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('shows rationale once when signed in and never asked', (
    tester,
  ) async {
    await pumpBootstrap(tester, permissionAsked: false, account: sampleAccount);

    expect(find.text('Stay on top of due tasks'), findsOneWidget);
    expect(find.text('Enable notifications'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Stay on top of due tasks'), findsNothing);
  });

  testWidgets('does not show rationale when already asked', (tester) async {
    await pumpBootstrap(tester, permissionAsked: true, account: sampleAccount);

    expect(find.text('Stay on top of due tasks'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('does not show rationale without an account', (tester) async {
    await pumpBootstrap(tester, permissionAsked: false);

    expect(find.text('Stay on top of due tasks'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
