import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class DootTypography {
  static TextTheme textTheme({required bool dark}) {
    final base = dark ? DootColors.darkInk : DootColors.ink;
    final muted = dark
        ? DootColors.darkInk.withValues(alpha: 0.7)
        : DootColors.inkMuted;

    final sans = GoogleFonts.sora(
      color: base,
      height: 1.4,
    );
    final display = sans.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.15,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 33),
      displayMedium: display.copyWith(fontSize: 26),
      displaySmall: display.copyWith(fontSize: 23),
      headlineLarge: display.copyWith(fontSize: 21),
      headlineMedium: display.copyWith(fontSize: 18),
      headlineSmall: display.copyWith(fontSize: 16),
      titleLarge: sans.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall: sans.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      bodyLarge: sans.copyWith(fontSize: 14),
      bodyMedium: sans.copyWith(fontSize: 12),
      bodySmall: sans.copyWith(fontSize: 11, color: muted),
      labelLarge: sans.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelMedium: sans.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
      labelSmall: sans.copyWith(fontSize: 9, fontWeight: FontWeight.w600),
    );
  }
}
