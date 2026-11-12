import 'package:material_ui/material_ui.dart';

/// Packaged brand imagery (mark + wordmark).
abstract final class DootBrandAssets {
  static const String package = 'dootdoot_design';
  static const String mark = 'assets/brand/mark.png';
  static const String wordmark = 'assets/brand/wordmark.png';

  /// App mark — white D/check with transparent background (place on [DootColors.brand]).
  static Widget markImage({double size = 96, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      mark,
      package: package,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }

  /// Wordmark — white “DootDoot” lettering with transparent background.
  static Widget wordmarkImage({
    double height = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      wordmark,
      package: package,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
