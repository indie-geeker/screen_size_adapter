import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'config.dart';
import 'internal/platform_detection.dart';
import 'internal/view_provider.dart';
import 'internal/view_sizing.dart';
import 'screen_size_helper.dart';
import 'screen_size_widget.dart';

/// Custom WidgetsFlutterBinding for screen-size adaptation.
///
/// Holds a per-view registry keyed by [FlutterView.viewId]. Each registered
/// view scales its [ViewConfiguration.devicePixelRatio] to make the
/// framework treat the view as if it were the registered design size.
/// Unregistered views fall through to stock Flutter behavior.
class ScreenSizeWidgetsFlutterBinding extends WidgetsFlutterBinding {
  /// Per-view sizing state keyed by FlutterView.viewId.
  final Map<int, ViewSizing> _views = {};

  ScreenSizeWidgetsFlutterBinding._() {
    // Auto-prune registry entries whose viewId is no longer in
    // platformDispatcher.views. Cheap defense against forgotten detachView.
    final existing = platformDispatcher.onMetricsChanged;
    platformDispatcher.onMetricsChanged = () {
      _pruneStaleViews();
      existing?.call();
    };
  }

  /// Initialize the screen-size adapter and register the primary view.
  ///
  /// Must be called before [runApp]. Returns the binding instance.
  ///
  /// Public signature is preserved from 0.3.0 for backward compatibility.
  /// Internally, the function arguments are translated into a
  /// [ScreenSizeAdapterConfig] that is stored against the primary view.
  static WidgetsBinding ensureInitialized(
    Size size, {
    ScreenSizeAdapterConfig? config,
  }) {
    WidgetsBinding? existing;
    try {
      existing = WidgetsBinding.instance;
    } on FlutterError {
      existing = null;
    }

    final resolvedConfig = config == null
        ? ScreenSizeAdapterConfig(designSize: size)
        : (config.designSize == size
            ? config
            : config.copyWith(designSize: size));

    if (existing == null) {
      final created = ScreenSizeWidgetsFlutterBinding._();
      created._registerPrimaryView(resolvedConfig);
      // Backward compat: Task 7 deletes this.
      ScreenSizeHelper.initialize(size, config: resolvedConfig);
      return created;
    }

    if (existing is ScreenSizeWidgetsFlutterBinding) {
      existing._registerPrimaryView(resolvedConfig);
      ScreenSizeHelper.initialize(size, config: resolvedConfig);
      existing.handleMetricsChanged();
      return existing;
    }

    throw StateError(
      'A ${existing.runtimeType} is already initialized. '
      'ScreenSizeWidgetsFlutterBinding.ensureInitialized must be called before '
      'any other binding initialization.',
    );
  }

  void _registerPrimaryView(ScreenSizeAdapterConfig config) {
    final primary = primaryView();
    if (primary == null) return;
    _views[primary.viewId] = ViewSizing(config);
  }

  // ── Public per-view registry API ─────────────────────────────────────

  /// Attach (or replace) the configuration for [view]. Triggers a layout pass.
  void attachView({
    required FlutterView view,
    required Size designSize,
    ScaleAxis scaleAxis = ScaleAxis.width,
    double? minScale,
    double? maxScale = 2.0,
    bool enableDesktopScaling = false,
  }) {
    _views[view.viewId] = ViewSizing(ScreenSizeAdapterConfig(
      designSize: designSize,
      scaleAxis: scaleAxis,
      minScale: minScale,
      maxScale: maxScale,
      enableDesktopScaling: enableDesktopScaling,
    ));
    handleMetricsChanged();
  }

  /// Mutate fields of an already-attached view's configuration.
  /// Throws [StateError] if [view] has no registration.
  void updateView({
    required FlutterView view,
    Size? designSize,
    ScaleAxis? scaleAxis,
    double? minScale,
    double? maxScale,
    bool? enableDesktopScaling,
  }) {
    final sizing = _views[view.viewId];
    if (sizing == null) {
      throw StateError(
        'updateView called for FlutterView ${view.viewId} which is not registered. '
        'Call attachView first.',
      );
    }
    sizing.config = sizing.config.copyWith(
      designSize: designSize,
      scaleAxis: scaleAxis,
      minScale: minScale,
      maxScale: maxScale,
      enableDesktopScaling: enableDesktopScaling,
    );
    handleMetricsChanged();
  }

  /// Reset [view]'s designSize to its current logical size.
  /// No-op if [view] is not registered.
  void resetView({required FlutterView view}) {
    final sizing = _views[view.viewId];
    if (sizing == null) return;
    final logical = Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
    sizing.config = sizing.config.copyWith(designSize: logical);
    handleMetricsChanged();
  }

  /// Remove [view] from the registry. No-op if not registered.
  void detachView(FlutterView view) {
    _views.remove(view.viewId);
    handleMetricsChanged();
  }

  /// The current scale factor for [viewId], or null if unmanaged.
  double? scaleForViewId(int viewId) => _views[viewId]?.scale;

  /// Test-only: returns the current config for [viewId], or null.
  ///
  /// Exposed for unit tests; not intended for production use.
  ScreenSizeAdapterConfig? configForViewId(int viewId) =>
      _views[viewId]?.config;

  // ── Auto-cleanup ────────────────────────────────────────────────────

  void _pruneStaleViews() {
    final liveIds = platformDispatcher.views.map((v) => v.viewId).toSet();
    _views.removeWhere((id, _) => !liveIds.contains(id));
  }

  // ── Overrides ───────────────────────────────────────────────────────

  @override
  ViewConfiguration createViewConfigurationFor(RenderView renderView) {
    final flutterView = renderView.flutterView;
    final sizing = _views[flutterView.viewId];
    if (sizing == null) {
      return super.createViewConfigurationFor(renderView);
    }
    sizing.recompute(
      originSize: Size(
        flutterView.physicalSize.width / flutterView.devicePixelRatio,
        flutterView.physicalSize.height / flutterView.devicePixelRatio,
      ),
      originDpr: flutterView.devicePixelRatio,
      isDesktop: isDesktopPlatform(),
    );

    // Backward compat: Task 7 deletes this.
    ScreenSizeHelper.instance.setup();

    final phys =
        BoxConstraints.fromViewConstraints(flutterView.physicalConstraints);
    return ViewConfiguration(
      physicalConstraints: phys,
      logicalConstraints: phys / sizing.effectiveDpr,
      devicePixelRatio: sizing.effectiveDpr,
    );
  }

  @override
  Widget wrapWithDefaultView(Widget rootWidget) {
    final view = primaryView();
    assert(view != null, 'No FlutterView available during wrapWithDefaultView');
    // Backward compat for ScreenSizeAdapter.of(context). Task 6 removes the wrap.
    return View(view: view!, child: ScreenSizeWidget(child: rootWidget));
  }

  @override
  void initInstances() {
    super.initInstances();
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
        PointerEventConverter.expand(packet.data, _devicePixelRatioForView),
      );
      if (!locked) _flushPointerEventQueue();
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
    return _views[viewId]?.effectiveDpr ??
        platformDispatcher.view(id: viewId)?.devicePixelRatio;
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
