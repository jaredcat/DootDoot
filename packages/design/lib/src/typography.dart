import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class DootTypography {
  static TextTheme textTheme({required bool dark}) {
    final base = dark ? DootColors.darkInk : DootColors.ink;
    final muted = dark
        ? DootColors.darkInk.withValues(alpha: 0.7)
        : DootColors.inkMuted;

    final display = GoogleFonts.fraunces(
      color: base,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final body = GoogleFonts.sourceSans3(
      color: base,
      height: 1.4,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 40),
      displayMedium: display.copyWith(fontSize: 32),
      displaySmall: display.copyWith(fontSize: 28),
      headlineLarge: display.copyWith(fontSize: 26),
      headlineMedium: display.copyWith(fontSize: 22),
      headlineSmall: display.copyWith(fontSize: 20),
      titleLarge: body.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: body.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleSmall: body.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(fontSize: 17),
      bodyMedium: body.copyWith(fontSize: 15),
      bodySmall: body.copyWith(fontSize: 13, color: muted),
      labelLarge: body.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
