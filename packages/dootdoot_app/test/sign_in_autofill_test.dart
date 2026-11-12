import 'dart:io';

import 'package:dootdoot_app/features/auth/sign_in_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _OfflineHttpOverrides();

  Future<void> pumpSignIn(
    WidgetTester tester, {
    required String kind,
    Size surface = const Size(800, 600),
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: SignInPage(kind: kind)),
      ),
    );
  }

  TextField fieldLabeled(WidgetTester tester, String label) {
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    return fields.firstWhere((field) {
      final decoration = field.decoration;
      return decoration is InputDecoration && decoration.labelText == label;
    });
  }

  testWidgets('password login fields are one autofill group', (tester) async {
    // Short viewport: a lazy list would not mount the password field, and
    // password managers would only see the email.
    await pumpSignIn(tester, kind: 'self', surface: const Size(320, 240));

    final group = tester.widget<AutofillGroup>(find.byType(AutofillGroup));
    expect(group.onDisposeAction, AutofillContextAction.cancel);
    expect(
      tester
          .state<AutofillGroupState>(find.byType(AutofillGroup))
          .autofillClients,
      hasLength(3),
    );

    final url = fieldLabeled(tester, 'Server URL');
    expect(url.autofillHints, [AutofillHints.url]);
    expect(url.keyboardType, TextInputType.url);
    expect(url.autocorrect, isFalse);
    expect(url.textInputAction, TextInputAction.next);

    final email = fieldLabeled(tester, 'Email');
    expect(email.autofillHints, [AutofillHints.username, AutofillHints.email]);
    expect(email.keyboardType, TextInputType.emailAddress);
    expect(email.autocorrect, isFalse);
    expect(email.smartQuotesType, SmartQuotesType.disabled);
    expect(email.smartDashesType, SmartDashesType.disabled);
    expect(email.textInputAction, TextInputAction.next);
    expect(email.decoration?.hintText, 'name@example.com');

    final password = fieldLabeled(tester, 'Password');
    expect(password.autofillHints, [AutofillHints.password]);
    expect(password.obscureText, isTrue);
    expect(password.keyboardType, TextInputType.text);
    expect(password.autocorrect, isFalse);
    expect(password.enableIMEPersonalizedLearning, isFalse);
    expect(password.textInputAction, TextInputAction.done);
    expect(password.inputFormatters, anyOf(isNull, isEmpty));
  });

  testWidgets('cloud login omits the server field', (tester) async {
    await pumpSignIn(tester, kind: 'cloud');

    expect(fieldLabeled(tester, 'Email').autofillHints, [
      AutofillHints.username,
      AutofillHints.email,
    ]);
    expect(fieldLabeled(tester, 'Password').autofillHints, [
      AutofillHints.password,
    ]);
    expect(find.text('Server URL'), findsNothing);
    expect(
      tester
          .state<AutofillGroupState>(find.byType(AutofillGroup))
          .autofillClients,
      hasLength(2),
    );

    // Let the optional identity-provider request fail offline.
    await tester.pumpAndSettle();
  });

  testWidgets('api token login is a password autofill field', (tester) async {
    await pumpSignIn(tester, kind: 'self');

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('Email'), findsNothing);
    expect(find.text('Password'), findsNothing);

    final token = fieldLabeled(tester, 'API token');
    expect(token.autofillHints, [AutofillHints.password]);
    expect(token.autocorrect, isFalse);
    expect(token.enableIMEPersonalizedLearning, isFalse);
    expect(token.textInputAction, TextInputAction.done);
    expect(
      tester
          .state<AutofillGroupState>(find.byType(AutofillGroup))
          .autofillClients,
      hasLength(2),
    );
  });
}

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _OfflineHttpClient();
}

class _OfflineHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return Future<HttpClientRequest>.error(const SocketException('offline'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future<Object?>.error(const SocketException('offline'));
    }
    return null;
  }
}
