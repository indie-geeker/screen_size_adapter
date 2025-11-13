part of '../screen_size_adapter.dart';


/// 屏幕适配辅助类（单例）
///
/// 管理设计稿尺寸、缩放比例和 MediaQuery 数据。
/// 通过 [ScreenSizeWidgetsFlutterBinding.ensureInitialized] 初始化。
class ScreenSizeHelper {
  /// 设计稿尺寸
  late Size designSize;

  /// 原始的 MediaQueryData（未缩放）
  late MediaQueryData originMediaQueryData;

  /// 缩放后的 MediaQueryData
  late MediaQueryData newMediaQueryData;

  /// 总体缩放比例
  /// 计算公式：
  /// - 竖屏：实际屏幕宽度 / 设计稿宽度
  /// - 横屏：实际屏幕高度 / 设计稿宽度
  double scale = 1.0;

  bool _isDesktop = false;
  bool _isInitialized = false;

  /// 是否为桌面平台（Windows/macOS/Linux）
  bool get isDesktop => _isDesktop;

  /// 是否为横屏模式（移动端）
  bool get isLandscape {
    return originMediaQueryData.size.width > originMediaQueryData.size.height
           && !_isDesktop;
  }

  factory ScreenSizeHelper() => instance;

  /// 获取单例实例
  static ScreenSizeHelper get instance => _getInstance();
  static ScreenSizeHelper? _instance;
  ScreenSizeHelper._internal();

  /// 初始化适配器（静态方法）
  ///
  /// 创建单例实例并设置设计稿尺寸。
  /// 此方法避免了在初始化时触发 _getInstance() 的检查逻辑。
  ///
  /// [size] 设计稿尺寸，建议使用标准尺寸如 Size(360, 640)
  static void initialize(Size size) {
    _instance ??= ScreenSizeHelper._internal();
    _instance!.setDesignSize(size);
  }

  /// 设置设计稿尺寸并初始化适配器
  ///
  /// [size] 设计稿尺寸，建议使用标准尺寸如 Size(360, 640)
  /// 注意：此方法不会立即调用 setup()，setup() 会在 Flutter view 准备好后自动调用
  void setDesignSize(Size size) {
    designSize = size;
    _isInitialized = true;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _isDesktop = true;
    }
  }

  /// 重置适配器到默认状态
  ///
  /// 将设计稿尺寸重置为当前屏幕尺寸，缩放比例重置为 1.0
  void reset() {
    final view = PlatformDispatcher.instance.implicitView!;
    originMediaQueryData = MediaQueryData.fromView(view);
    designSize = originMediaQueryData.size;
    if (designSize.width > designSize.height && !_isDesktop) {
      designSize = designSize.flipped;
    }
    scale = 1.0;
  }

  void setup() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) {
      // View not ready yet, use default values
      originMediaQueryData = MediaQueryData(size: designSize);
      newMediaQueryData = originMediaQueryData;
      return;
    }

    originMediaQueryData = MediaQueryData.fromView(view);

    // 桌面平台特殊处理
    if (_isDesktop && scale != 1.0) {
      newMediaQueryData = originMediaQueryData.copyWithScale();
      return;
    }

    // 横屏判断
    bool isLandscape = view.physicalSize.width > view.physicalSize.height && !_isDesktop;

    if (isLandscape) {
      // 横屏模式：使用屏幕高度与设计稿宽度的比例
      scale = originMediaQueryData.size.height / designSize.width;
    } else {
      // 竖屏模式：使用屏幕宽度与设计稿宽度的比例
      scale = originMediaQueryData.size.width / designSize.width;
    }

    // 确保 scale 是有效值
    if (scale.isNaN || scale.isInfinite || scale <= 0) {
      scale = 1.0;
    }

    newMediaQueryData = originMediaQueryData.copyWithScale();
  }

  static ScreenSizeHelper _getInstance() {
    _instance ??= ScreenSizeHelper._internal();

    if (!_instance!._isInitialized) {
      throw StateError(
        'ScreenSizeAdapter not initialized.\n'
        'Please call ScreenSizeWidgetsFlutterBinding.ensureInitialized(designSize) '
        'before runApp().\n\n'
        'Example:\n'
        '  void main() {\n'
        '    ScreenSizeWidgetsFlutterBinding.ensureInitialized(Size(360, 640));\n'
        '    runApp(MyApp());\n'
        '  }'
      );
    }
    return _instance!;
  }
}