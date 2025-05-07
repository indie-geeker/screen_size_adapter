part of 'screen_size_adapter.dart';
class DesignSizeWidgetsFlutterBinding extends WidgetsFlutterBinding {
  final Size designSize;

  DesignSizeWidgetsFlutterBinding(this.designSize);

  static WidgetsBinding ensureInitialized(Size size) {
    ScreenSizeHelper.instance.setDesignSize(size);
    DesignSizeWidgetsFlutterBinding(size);
    return WidgetsBinding.instance;
  }

  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) {
    var view = renderView.flutterView;
    ScreenSizeHelper.instance.setup();
    final BoxConstraints physicalConstraints =
    BoxConstraints.fromViewConstraints(view.physicalConstraints);
    final double devicePixelRatio =
        ScreenSizeHelper.instance.data.devicePixelRatio;
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
      return ScreenSizeHelper.instance.data.devicePixelRatio;
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