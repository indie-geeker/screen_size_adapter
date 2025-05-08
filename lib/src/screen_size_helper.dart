part of '../screen_size_adapter.dart';


class ScreenSizeHelper {
  //设计尺寸
  late Size designSize;
  late MediaQueryData originMediaQueryData;
  late MediaQueryData newMediaQueryData;
  double scale = 1.0; // 总体缩放比例，用于兼容现有代码
  // double fontScale = 1.0; // 文字缩放比例
  // double widthScale = 1.0; // 宽度缩放比例
  // double heightScale = 1.0; // 高度缩放比例

  bool _isDesktop = false;

  factory ScreenSizeHelper() => instance;
  static ScreenSizeHelper get instance => _getInstance();
  static ScreenSizeHelper? _instance;
  ScreenSizeHelper._internal();

  //设置设计稿的大小
  void setDesignSize(Size size) {
    designSize = size;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _isDesktop = true;
    }
    setup();
  }

  void reset() {
    final view = PlatformDispatcher.instance.implicitView!;
    originMediaQueryData = MediaQueryData.fromView(view);
    designSize = originMediaQueryData.size;
    if (designSize.width > designSize.height && !_isDesktop) {
      designSize = designSize.flipped;
    }
    scale = 1.0;
    // widthScale = 1.0;
    // heightScale = 1.0;
    // fontScale = 1.0;
  }

  void setup() {
    final view = PlatformDispatcher.instance.implicitView!;
    originMediaQueryData = MediaQueryData.fromView(view);
    if (_isDesktop && scale != 1.0) {
      newMediaQueryData = originMediaQueryData.copyWithScale();
      return;
    }

    // 重置所有缩放系数为默认值
    // fontScale = 1.0;
    // widthScale = 1.0;
    // heightScale = 1.0;

    // 横屏判断
    bool isLandscape = view.physicalSize.width > view.physicalSize.height && !_isDesktop;

    if (isLandscape) {
      // 横屏模式下的处理
      // 宽度缩放 - 使用屏幕较小的宽度与设计宽度的比值
      // widthScale = originData.size.height / designSize.width;
      // 高度缩放 - 使用屏幕高度与设计高度的比值
      // heightScale = originData.size.height / designSize.height;
      // 文字缩放 - 使用原始的屏幕高度与设计宽度的比值
      // fontScale = (originData.size.height / designSize.width) / widthScale;

      // 保持兼容性的总体缩放
      scale = originMediaQueryData.size.height / designSize.width;
    } else {
      // 竖屏模式下的处理
      // widthScale = originData.size.width / designSize.width;
      // heightScale = widthScale; // 竖屏时保持宽高等比缩放
      scale = originMediaQueryData.size.width / designSize.width;;
    }
    
    newMediaQueryData = originMediaQueryData.copyWithScale();
  }

  static ScreenSizeHelper _getInstance() {
    _instance ??= ScreenSizeHelper._internal();
    return _instance!;
  }
}