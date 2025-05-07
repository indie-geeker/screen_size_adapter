part of 'screen_size_adapter.dart';

class ScreenSizeHelper {
  //设计稿大小
  late Size designSize;
  late MediaQueryData originData;
  late MediaQueryData data;
  double scale = 1.0;

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
    originData = MediaQueryData.fromView(view);
    designSize = originData.size;
    if (designSize.width > designSize.height && !_isDesktop) {
      designSize = designSize.flipped;
    }
    scale = 1.0;
  }

  void setup() {
    final view = PlatformDispatcher.instance.implicitView!;
    originData = MediaQueryData.fromView(view);
    if (_isDesktop && scale != 1.0) {
      data = originData.design();
      return;
    }
    //横屏
    if (view.physicalSize.width > view.physicalSize.height && !_isDesktop) {
      scale = originData.size.height / designSize.width;
    } else {
      scale = originData.size.width / designSize.width;
    }
    data = originData.design();
  }

  static ScreenSizeHelper _getInstance() {
    _instance ??= ScreenSizeHelper._internal();
    return _instance!;
  }
}