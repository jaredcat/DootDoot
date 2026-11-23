import 'package:material_ui/material_ui.dart';

/// Tududi shared palette (`frontend/constants/colorPalette.ts`).
class NotePaletteColor {
  const NotePaletteColor({
    required this.key,
    required this.name,
    required this.value,
    required this.dark,
  });

  final String key;
  final String name;
  final Color value;
  final Color dark;
}

const notePalette = <NotePaletteColor>[
  NotePaletteColor(
    key: 'red',
    name: 'Red',
    value: Color(0xFFB91C1C),
    dark: Color(0xFFF87171),
  ),
  NotePaletteColor(
    key: 'orange',
    name: 'Orange',
    value: Color(0xFFC2410C),
    dark: Color(0xFFFB923C),
  ),
  NotePaletteColor(
    key: 'yellow',
    name: 'Yellow',
    value: Color(0xFFCA8A04),
    dark: Color(0xFFFACC15),
  ),
  NotePaletteColor(
    key: 'green',
    name: 'Green',
    value: Color(0xFF15803D),
    dark: Color(0xFF4ADE80),
  ),
  NotePaletteColor(
    key: 'teal',
    name: 'Teal',
    value: Color(0xFF0F766E),
    dark: Color(0xFF2DD4BF),
  ),
  NotePaletteColor(
    key: 'cyan',
    name: 'Cyan',
    value: Color(0xFF0E7490),
    dark: Color(0xFF22D3EE),
  ),
  NotePaletteColor(
    key: 'blue',
    name: 'Blue',
    value: Color(0xFF1D4ED8),
    dark: Color(0xFF60A5FA),
  ),
  NotePaletteColor(
    key: 'indigo',
    name: 'Indigo',
    value: Color(0xFF4338CA),
    dark: Color(0xFF818CF8),
  ),
  NotePaletteColor(
    key: 'purple',
    name: 'Purple',
    value: Color(0xFF7E22CE),
    dark: Color(0xFFC084FC),
  ),
  NotePaletteColor(
    key: 'pink',
    name: 'Pink',
    value: Color(0xFFBE185D),
    dark: Color(0xFFF472B6),
  ),
  NotePaletteColor(
    key: 'gray',
    name: 'Gray',
    value: Color(0xFF374151),
    dark: Color(0xFF9CA3AF),
  ),
];

NotePaletteColor? resolveNoteColor(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final key = raw.trim().toLowerCase();
  for (final c in notePalette) {
    if (c.key == key) return c;
    if (_hex(c.value) == key || _hex(c.dark) == key) return c;
  }
  if (RegExp(r'^#[0-9a-f]{6}$', caseSensitive: false).hasMatch(key)) {
    final color = Color(int.parse(key.substring(1), radix: 16) + 0xFF000000);
    return NotePaletteColor(
      key: 'custom',
      name: raw,
      value: color,
      dark: color,
    );
  }
  return null;
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

/// Tududi luminance rule: &lt; 0.4 → light text.
bool noteColorNeedsLightText(Color background) {
  final argb = background.toARGB32();
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance < 0.4;
}

Color noteSurfaceColor(NotePaletteColor? palette, {required bool isDark}) {
  if (palette == null) return Colors.transparent;
  // Soft wash of the accent over the page (≈12–16% like Tududi softBg).
  final accent = isDark ? palette.dark : palette.value;
  return Color.alphaBlend(
    accent.withValues(alpha: isDark ? 0.16 : 0.12),
    isDark ? const Color(0xFF111827) : Colors.white,
  );
}

Color? noteForegroundOn(NotePaletteColor? palette, {required bool isDark}) {
  if (palette == null) return null;
  final bg = noteSurfaceColor(palette, isDark: isDark);
  return noteColorNeedsLightText(bg)
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF333333);
}
