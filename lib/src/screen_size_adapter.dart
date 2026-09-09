import 'package:flutter/widgets.dart';

import 'config.dart';
import 'internal/compute_scale.dart' as sizing;
import 'internal/platform_detection.dart';
import 'internal/scale_media_query.dart';
import 'screen_size_metrics.dart';

/// Lays out a complete app in design units using a root rendering transform.
///
/// Mount once below each [View], above MaterialApp/Navigator/Overlay. This
/// widget keeps the standard binding, native RenderView DPR and pointer
/// dispatcher. MediaQuery.size = originSize / scale; the configured design
/// size is a scale reference, not a forced aspect ratio.
///
/// Change [config] or [enabled] by rebuilding this same widget. The child tree
/// stays mounted when crossing scale 1, preserving navigation and input state.
/// Native text geometry and raw wheel deltas have known Flutter SDK gaps;
/// see the README and the explicit SDK acceptance gates before shipping.
class ScreenSizeAdapter extends StatelessWidget {
  const ScreenSizeAdapter({
    super.key,
    required this.config,
    required this.child,
    this.enabled = true,
  });

  final ScreenSizeAdapterConfig config;
  final Widget child;

  /// Uses native layout and MediaQuery metrics when false, regardless of clamps.
  final bool enabled;

  /// Pure scale calculation; also validates configuration values.
  static double computeScale({
    required Size origin,
    required ScreenSizeAdapterConfig config,
    required bool isDesktop,
  }) =>
      sizing.computeScale(origin: origin, config: config, isDesktop: isDesktop);

  /// Subscribes to the enclosing adapter's current view metrics.
  static ScreenSizeMetrics of(BuildContext context) =>
      ScreenSizeMetrics.of(context);

  /// Returns 1 outside an adapter; subscribes to changes inside one.
  static double scaleOf(BuildContext context) =>
      ScreenSizeMetrics.maybeOf(context)?.scale ?? 1;

  /// Native logical view size, with reactive updates inside and outside adapters.
  static Size originSizeOf(BuildContext context) {
    final metrics = ScreenSizeMetrics.maybeOf(context);
    if (metrics != null) return metrics.originSize;
    MediaQuery.maybeOf(context);
    final view = View.of(context);
    return view.physicalSize / view.devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    if (ScreenSizeMetrics.maybeOf(context) != null) {
      throw FlutterError(
        'Mount ScreenSizeAdapter once per FlutterView, above the complete app.',
      );
    }
    final native = MediaQuery.of(context);
    final computed = computeScale(
      origin: native.size,
      config: config,
      isDesktop: isDesktopPlatform(),
    );
    final scale = enabled ? computed : 1.0;
    final metrics = ScreenSizeMetrics(
      viewId: view.viewId,
      originSize: native.size,
      nativeDpr: view.devicePixelRatio,
      scale: scale,
    );
    return ScreenSizeMetricsScope(
      metrics: metrics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedWidth ||
              !constraints.hasBoundedHeight ||
              constraints.biggest != native.size) {
            throw FlutterError(
              'ScreenSizeAdapter requires the complete bounded View. '
              'Place it above MaterialApp, not inside a page, SafeArea or scrollable.',
            );
          }
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: metrics.designSize.width,
              maxWidth: metrics.designSize.width,
              minHeight: metrics.designSize.height,
              maxHeight: metrics.designSize.height,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: MediaQuery(
                  data: scaleMediaQueryData(native, scale),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
