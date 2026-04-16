part of '../screen_size_adapter.dart';
extension MediaQueryDataExt on MediaQueryData {
  MediaQueryData copyWithScale() {
    final scale = ScreenSizeHelper.instance.scale;
    return copyWith(
      size: size / scale,
      devicePixelRatio: devicePixelRatio * scale,
      // padding, viewPadding, viewInsets are intentionally NOT scaled.
      // These represent physical device properties (notch, home indicator, keyboard).
    );
  }
}