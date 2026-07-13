import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'config.dart';
import 'internal/config_validation.dart';
import 'internal/platform_detection.dart';
import 'internal/view_provider.dart';
import 'internal/view_sizing.dart';
import 'screen_size_adapter_scope.dart';

/// Custom WidgetsFlutterBinding for screen-size adaptation.
///
/// Holds a per-view registry keyed by [FlutterView.viewId]. Each registered
/// view scales its [ViewConfiguration.devicePixelRatio] to make the
/// framework treat the view as if it were the registered design size.
/// Unregistered views fall through to stock Flutter behavior.
///
/// The implicit-view `runApp` path is stable. Same-engine secondary-view
/// registration is experimental and must be wired and verified by the host.
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

  /// Initialize the screen-size adapter and register the implicit view.
  ///
  /// Must be called before [runApp]. Returns the binding instance. If the
  /// dispatcher has no implicit view, automatic registration is skipped and
  /// host-created views must call [attachView] explicitly.
  static ScreenSizeWidgetsFlutterBinding ensureInitialized(
    ScreenSizeAdapterConfig config,
  ) {
    validateConfigValues(
      designSize: config.designSize,
      minScale: config.minScale,
      maxScale: config.maxScale,
    );
    final existing = _bindingOrNull();

    if (existing == null) {
      final created = ScreenSizeWidgetsFlutterBinding._();
      created._registerPrimaryView(config);
      return created;
    }

    if (existing is ScreenSizeWidgetsFlutterBinding) {
      existing._registerPrimaryView(config);
      existing.handleMetricsChanged();
      return existing;
    }

    throw StateError(
      'A ${existing.runtimeType} is already initialized. '
      'ScreenSizeWidgetsFlutterBinding.ensureInitialized must be called before '
      'any other binding initialization.',
    );
  }

  static WidgetsBinding? _bindingOrNull() {
    try {
      return WidgetsBinding.instance;
    } on FlutterError {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// The installed adapter binding.
  ///
  /// Throws [StateError] when a different [WidgetsBinding] is active. Use after
  /// [ensureInitialized] has installed this binding.
  static ScreenSizeWidgetsFlutterBinding get instance {
    final binding = WidgetsBinding.instance;
    if (binding is ScreenSizeWidgetsFlutterBinding) return binding;
    throw StateError(
      'ScreenSizeWidgetsFlutterBinding is not installed. '
      'Call ScreenSizeWidgetsFlutterBinding.ensureInitialized(...) before '
      'accessing ScreenSizeWidgetsFlutterBinding.instance.',
    );
  }

  void _registerPrimaryView(ScreenSizeAdapterConfig config) {
    final primary = primaryView();
    if (primary == null) return;
    _views[primary.viewId] = ViewSizing(config);
  }

  // ── Public per-view registry API ─────────────────────────────────────

  /// Register (or replace) the screen-size configuration for [view].
  ///
  /// Calling on a view that is already attached replaces its config
  /// entirely. Triggers `handleMetricsChanged()` so Flutter's layout
  /// pipeline applies the new configuration on the next frame.
  ///
  /// Use this experimental API for host-created [FlutterView]s (embedded
  /// views, secondary windows, multi-display). Only the dispatcher's implicit
  /// view is registered automatically by [ensureInitialized].
  void attachView({
    required FlutterView view,
    required ScreenSizeAdapterConfig config,
  }) {
    validateConfigValues(
      designSize: config.designSize,
      minScale: config.minScale,
      maxScale: config.maxScale,
    );
    _views[view.viewId] = ViewSizing(config);
    handleMetricsChanged();
  }

  /// Replace an already-registered view's configuration.
  /// Throws [StateError] if [view] has no registration — call [attachView]
  /// first.
  ///
  /// Triggers `handleMetricsChanged()` so the next layout pass picks up
  /// the new values.
  ///
  void updateView({
    required FlutterView view,
    required ScreenSizeAdapterConfig config,
  }) {
    final sizing = _views[view.viewId];
    if (sizing == null) {
      throw StateError(
        'updateView called for FlutterView ${view.viewId} which is not registered. '
        'Call attachView first.',
      );
    }
    validateConfigValues(
      designSize: config.designSize,
      minScale: config.minScale,
      maxScale: config.maxScale,
    );
    sizing.config = config;
    handleMetricsChanged();
  }

  /// Reset [view]'s `designSize` to the view's current logical size
  /// (physicalSize / devicePixelRatio) and clear both scale bounds, restoring
  /// an effective scale of `1.0`.
  ///
  /// Does NOT revert to the value passed to [attachView] — the original
  /// registration is overwritten. To restore a known bounded config, call
  /// [attachView] with the desired values.
  ///
  /// No-op if [view] is not registered.
  void resetView({required FlutterView view}) {
    final sizing = _views[view.viewId];
    if (sizing == null) return;
    final logical = Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
    sizing.config = sizing.config.copyWith(
      designSize: logical,
      clearMinScale: true,
      clearMaxScale: true,
    );
    handleMetricsChanged();
  }

  /// Remove [view] from the registry. No-op if not registered.
  ///
  /// Subsequent `createViewConfigurationFor` calls for this view fall
  /// through to stock Flutter behavior — the view will render at its
  /// native devicePixelRatio. Trigger a layout pass via
  /// `handleMetricsChanged()` immediately so the change is visible on
  /// the next frame; expect a brief discontinuity if the view was
  /// previously rendering at a scaled DPR.
  void detachView(FlutterView view) {
    _views.remove(view.viewId);
    handleMetricsChanged();
  }

  /// The most-recently-computed scale factor for [view], or `null` if
  /// the view is not registered.
  ///
  /// May return `1.0` for a registered view that has not yet undergone
  /// its first layout pass. Read inside or after a frame for accurate
  /// values.
  double? scaleForView(FlutterView view) => _views[view.viewId]?.scale;

  /// Returns the current config for [view], or null when not registered.
  ScreenSizeAdapterConfig? configForView(FlutterView view) =>
      _views[view.viewId]?.config;

  // ── Auto-cleanup ────────────────────────────────────────────────────

  void _pruneStaleViews() {
    final liveIds = platformDispatcher.views.map((v) => v.viewId).toSet();
    _views.removeWhere((id, _) => !liveIds.contains(id));
  }

  // ── Overrides ───────────────────────────────────────────────────────

  /// Wraps the implicit view's root widget so the per-view scale is
  /// reflected in [MediaQuery] (size, devicePixelRatio, padding,
  /// viewInsets, etc.). The binding's `createViewConfigurationFor` only
  /// affects `RenderView.configuration`, which Flutter's
  /// `MediaQuery.fromView` does not consult — without this wrap,
  /// `MediaQuery.sizeOf(context)` would return the unscaled native size.
  ///
  /// For experimental non-implicit views attached by a host (`runWidget` + an
  /// explicit [View] widget), wrap the [View]'s child with
  /// [ScreenSizeAdapterScope] manually.
  @override
  Widget wrapWithDefaultView(Widget rootWidget) {
    return super.wrapWithDefaultView(ScreenSizeAdapterScope(child: rootWidget));
  }

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

    final phys = BoxConstraints.fromViewConstraints(
      flutterView.physicalConstraints,
    );
    return ViewConfiguration(
      physicalConstraints: phys,
      logicalConstraints: phys / sizing.effectiveDpr,
      devicePixelRatio: sizing.effectiveDpr,
    );
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
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'gestures library',
          context: ErrorDescription('while handling a pointer data packet'),
        ),
      );
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
