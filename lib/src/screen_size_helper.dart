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

  /// 运行时配置
  ScreenSizeAdapterConfig config = const ScreenSizeAdapterConfig();

  bool _isDesktop = false;
  bool _isInitialized = false;

  /// 是否为桌面平台（Windows/macOS/Linux）
  bool get isDesktop => _isDesktop;

  /// 当前平台是否需要应用设计稿缩放。
  ///
  /// 规则：
  /// - 移动端默认开启
  /// - 桌面端默认关闭，可通过配置开启
  bool get shouldApplyScale => !_isDesktop || config.enableDesktopScaling;

  /// 是否为横屏模式（移动端）
  bool get isLandscape {
    return originMediaQueryData.size.width > originMediaQueryData.size.height &&
        !_isDesktop;
  }

  factory ScreenSizeHelper() => instance;

  /// 获取单例实例
  static ScreenSizeHelper get instance => _getInstance();
  static ScreenSizeHelper? _instance;
  ScreenSizeHelper._internal();

  /// 初始化适配器（静态方法）
  ///
  /// 创建单例实例并设置设计稿尺寸。
  /// [size] 设计稿尺寸，建议使用标准尺寸如 Size(360, 640)
  static void initialize(
    Size size, {
    ScreenSizeAdapterConfig config = const ScreenSizeAdapterConfig(),
  }) {
    _instance ??= ScreenSizeHelper._internal();
    _instance!._applyConfig(config);
    _instance!.setDesignSize(size);
  }

  /// 用于测试环境的快速初始化。
  ///
  /// 默认逻辑尺寸为 [size]，可通过 [logicalSize] 覆盖。
  static void initializeForTest(
    Size size, {
    Size? logicalSize,
    bool? isDesktop,
    ScreenSizeAdapterConfig config = const ScreenSizeAdapterConfig(),
  }) {
    _instance ??= ScreenSizeHelper._internal();
    _instance!._applyConfig(config);
    _instance!.setDesignSize(size);

    if (isDesktop != null) {
      _instance!._isDesktop = isDesktop;
    }

    final Size resolvedLogicalSize = logicalSize ?? size;
    _instance!.originMediaQueryData = MediaQueryData(size: resolvedLogicalSize);

    if (!_instance!.shouldApplyScale) {
      _instance!.scale = 1.0;
      _instance!.newMediaQueryData = _instance!.originMediaQueryData;
      return;
    }

    final bool isLandscape =
        resolvedLogicalSize.width > resolvedLogicalSize.height &&
        !_instance!._isDesktop;

    if (isLandscape) {
      _instance!.scale = resolvedLogicalSize.height / size.width;
    } else {
      _instance!.scale = resolvedLogicalSize.width / size.width;
    }

    if (_instance!.scale.isNaN ||
        _instance!.scale.isInfinite ||
        _instance!.scale <= 0) {
      _instance!.scale = 1.0;
    }

    _instance!._clampScale();

    _instance!.newMediaQueryData =
        _instance!.originMediaQueryData.copyWithScale();
  }

  void _applyConfig(ScreenSizeAdapterConfig value) {
    config = value;
  }

  /// 设置设计稿尺寸并初始化适配器
  ///
  /// [size] 设计稿尺寸，建议使用标准尺寸如 Size(360, 640)
  /// 注意：此方法不会立即触发整棵树重布局，需要由 binding 或 controller 触发。
  void setDesignSize(Size size) {
    designSize = size;
    _isInitialized = true;
    _isDesktop = _detectDesktopPlatform();

    // 在 view 尚未准备好时提供安全默认值，避免扩展方法提前访问 late 字段失败。
    originMediaQueryData = MediaQueryData(size: size);
    newMediaQueryData = originMediaQueryData;
    scale = 1.0;
  }

  bool _detectDesktopPlatform() {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
  }

  /// 重置适配器到默认状态
  ///
  /// 将设计稿尺寸重置为当前屏幕尺寸，缩放比例重置为 1.0
  void reset() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) {
      originMediaQueryData = MediaQueryData(size: designSize);
      newMediaQueryData = originMediaQueryData;
      scale = 1.0;
      return;
    }

    originMediaQueryData = MediaQueryData.fromView(view);
    designSize = originMediaQueryData.size;
    if (designSize.width > designSize.height && !_isDesktop) {
      designSize = designSize.flipped;
    }
    scale = 1.0;
    newMediaQueryData = originMediaQueryData.copyWithScale();
  }

  void setup() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) {
      // View not ready yet, use default values.
      originMediaQueryData = MediaQueryData(size: designSize);
      newMediaQueryData = originMediaQueryData;
      scale = 1.0;
      return;
    }

    originMediaQueryData = MediaQueryData.fromView(view);

    if (!shouldApplyScale) {
      scale = 1.0;
      newMediaQueryData = originMediaQueryData;
      return;
    }

    final bool isLandscape =
        view.physicalSize.width > view.physicalSize.height && !_isDesktop;

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

    _clampScale();

    newMediaQueryData = originMediaQueryData.copyWithScale();
  }

  void _clampScale() {
    if (config.maxScale != null && scale > config.maxScale!) {
      scale = config.maxScale!;
    }
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
        '  }',
      );
    }
    return _instance!;
  }
}
