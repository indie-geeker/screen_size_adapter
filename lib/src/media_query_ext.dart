part of '../screen_size_adapter.dart';
extension MediaQueryDataExt on MediaQueryData {
  MediaQueryData copyWithScale() {
    final scale = ScreenSizeHelper.instance.scale;
    // final widthScale = ScreenSizeHelper.instance.widthScale;
    // final heightScale = ScreenSizeHelper.instance.heightScale;
    // final fontScale = ScreenSizeHelper.instance.fontScale;
    return copyWith(
      // textScaler: TextScaler.linear(fontScale),
      size: size / scale,
      devicePixelRatio: devicePixelRatio * scale,
      viewInsets: viewInsets / scale,
      viewPadding: viewPadding / scale,
      padding: padding / scale,
    );
  }
}