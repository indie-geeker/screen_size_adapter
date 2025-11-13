part of '../screen_size_adapter.dart';

/// 自定义 WidgetsFlutterBinding，用于屏幕适配
///
/// 拦截 Flutter 的渲染管道，注入缩放后的 MediaQuery 和处理指针事件。
class ScreenSizeWidgetsFlutterBinding extends WidgetsFlutterBinding {
  final Size designSize;

  ScreenSizeWidgetsFlutterBinding._(this.designSize) {
    ScreenSizeHelper.initialize(designSize);
  }

  ///  初始化屏幕适配器
  ///
  /// 必须在 [runApp] 之前调用。
  ///
  /// [size] 设计稿尺寸，建议使用标准尺寸如 Size(360, 640)
  ///
  /// 使用示例：
  /// ```dart
  /// void main() {
  ///   ScreenSizeWidgetsFlutterBinding.ensureInitialized(Size(360, 640));
  ///   runApp(MyApp());
  /// }
  /// ```
  static WidgetsBinding ensureInitialized(Size size) {
    return ScreenSizeWidgetsFlutterBinding._(size);
  }

  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) {
    var view = renderView.flutterView;
    ScreenSizeHelper.instance.setup();

    final BoxConstraints physicalConstraints =
        BoxConstraints.fromViewConstraints(view.physicalConstraints);
    final double devicePixelRatio =
        ScreenSizeHelper.instance.newMediaQueryData.devicePixelRatio;
    return ViewConfiguration(
      physicalConstraints: physicalConstraints,
      logicalConstraints: physicalConstraints / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
    );
  }

  @override
  Widget wrapWithDefaultView(Widget rootWidget) {
    final view = platformDispatcher.implicitView!;
    return View(view: view, child: ScreenSizeWidget(child: rootWidget));
  }

  @override
  void initInstances() {
    super.initInstances();
    //hooks GestureBinding
    PlatformDispatcher.instance.onPointerDataPacket = _handlePointerDataPacket;
  }

  @override
  void unlocked() {
    super.unlocked();
    _flushPointerEventQueue();
  }

  final Queue<PointerEvent> _pendingPointerEvents = Queue<PointerEvent>();

  void _handlePointerDataPacket(PointerDataPacket packet) {
    try {
      _pendingPointerEvents.addAll(
          PointerEventConverter.expand(packet.data, _devicePixelRatioForView));
      if (!locked) {
        _flushPointerEventQueue();
      }
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'gestures library',
        context: ErrorDescription('while handling a pointer data packet'),
      ));
    }
  }

  double? _devicePixelRatioForView(int viewId) {
    if (viewId == 0) {
      return ScreenSizeHelper.instance.newMediaQueryData.devicePixelRatio;
    }
    return platformDispatcher.view(id: viewId)?.devicePixelRatio;
  }

  @override
  void cancelPointer(int pointer) {
    if (_pendingPointerEvents.isEmpty && !locked) {
      scheduleMicrotask(_flushPointerEventQueue);
    }
    _pendingPointerEvents.addFirst(PointerCancelEvent(pointer: pointer));
  }

  void _flushPointerEventQueue() {
    assert(!locked);

    while (_pendingPointerEvents.isNotEmpty) {
      handlePointerEvent(_pendingPointerEvents.removeFirst());
    }
  }
}