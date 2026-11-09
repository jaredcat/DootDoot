import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

abstract final class DootTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DootColors.sea,
      brightness: Brightness.light,
      primary: DootColors.sea,
      onPrimary: Colors.white,
      secondary: DootColors.ink,
      surface: DootColors.cloud,
      error: DootColors.coral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DootColors.cloud,
      textTheme: DootTypography.textTheme(dark: false),
      appBarTheme: AppBarTheme(
        backgroundColor: DootColors.cloud.withValues(alpha: 0.92),
        foregroundColor: DootColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: DootTypography.textTheme(dark: false).titleLarge,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DootColors.sea,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DootColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DootColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DootColors.sea, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: DootColors.line, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: DootColors.foam,
        selectedColor: DootColors.sea.withValues(alpha: 0.15),
        labelStyle: DootTypography.textTheme(dark: false).labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: DootColors.foam,
        labelTextStyle: WidgetStatePropertyAll(
          DootTypography.textTheme(dark: false).labelSmall,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DootColors.seaSoft,
      brightness: Brightness.dark,
      primary: DootColors.seaSoft,
      onPrimary: DootColors.ink,
      surface: DootColors.darkSurface,
      error: DootColors.coral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DootColors.darkSurface,
      textTheme: DootTypography.textTheme(dark: true),
      appBarTheme: AppBarTheme(
        backgroundColor: DootColors.darkSurface.withValues(alpha: 0.92),
        foregroundColor: DootColors.darkInk,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: DootTypography.textTheme(dark: true).titleLarge,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DootColors.seaSoft,
        foregroundColor: DootColors.ink,
      ),
      cardTheme: CardThemeData(
        color: DootColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DootColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DootColors.darkInk.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DootColors.darkInk.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DootColors.seaSoft, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DootColors.darkCard,
        indicatorColor: DootColors.seaSoft.withValues(alpha: 0.25),
      ),
    );
  }
}
