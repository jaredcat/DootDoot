import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  configureDesignForTests();

  test('light and dark themes build', () {
    expect(DootTheme.light().colorScheme.primary, DootColors.sea);
    expect(DootTheme.dark().brightness, Brightness.dark);
  });
}
