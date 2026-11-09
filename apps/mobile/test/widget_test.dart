import 'package:dootdoot_app/dootdoot_app.dart';
import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  configureDesignForTests();

  testWidgets('shows onboarding when no accounts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const DootdootApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DootDoot'), findsWidgets);
    expect(find.textContaining('unofficial', findRichText: true), findsWidgets);
  });
}
