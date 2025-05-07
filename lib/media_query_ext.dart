part of 'screen_size_adapter.dart';
extension MediaQueryDataExt on MediaQueryData {
  MediaQueryData design() {
    final scale = ScreenSizeHelper.instance.scale;
    return copyWith(
      size: size / scale,
      devicePixelRatio: devicePixelRatio * scale,
      viewInsets: viewInsets / scale,
      viewPadding: viewPadding / scale,
      padding: padding / scale,
    );
  }
}