import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class DootTypography {
  static TextTheme textTheme({required bool dark}) {
    final base = dark ? DootColors.darkInk : DootColors.ink;
    final muted = dark
        ? DootColors.darkInk.withValues(alpha: 0.7)
        : DootColors.inkMuted;

    // Single sans family for all roles — no serif/display mix.
    final sans = GoogleFonts.sourceSans3(
      color: base,
      height: 1.4,
    );
    final display = sans.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.15,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 40),
      displayMedium: display.copyWith(fontSize: 32),
      displaySmall: display.copyWith(fontSize: 28),
      headlineLarge: display.copyWith(fontSize: 26),
      headlineMedium: display.copyWith(fontSize: 22),
      headlineSmall: display.copyWith(fontSize: 20),
      titleLarge: sans.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: sans.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleSmall: sans.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: sans.copyWith(fontSize: 17),
      bodyMedium: sans.copyWith(fontSize: 15),
      bodySmall: sans.copyWith(fontSize: 13, color: muted),
      labelLarge: sans.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: sans.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: sans.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
