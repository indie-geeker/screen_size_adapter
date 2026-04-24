import 'package:flutter/widgets.dart';

extension MediaQueryDataExt on MediaQueryData {
  /// Returns a copy of this [MediaQueryData] with `size` divided by [scale] and
  /// `devicePixelRatio` multiplied by [scale]. Intentionally does NOT scale
  /// `padding`, `viewPadding`, or `viewInsets` — those are physical device
  /// properties (notch, home indicator, keyboard).
  MediaQueryData copyWithScale(double scale) {
    return copyWith(
      size: size / scale,
      devicePixelRatio: devicePixelRatio * scale,
    );
  }
}
