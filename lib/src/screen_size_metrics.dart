import 'package:flutter/widgets.dart';

/// Immutable metrics for one root adapter. Sizes use logical, not physical, units.
@immutable
class ScreenSizeMetrics {
  const ScreenSizeMetrics({
    required this.viewId,
    required this.originSize,
    required this.nativeDpr,
    required this.scale,
  });

  final int viewId;
  final Size originSize;
  final double nativeDpr;
  final double scale;
  Size get designSize => originSize / scale;

  /// Density for image asset selection in the scaled design subtree.
  double get assetDpr => nativeDpr * scale;

  /// Subscribes to metrics owned by the same View, if an adapter is present.
  static ScreenSizeMetrics? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ScreenSizeMetricsScope>();
    return scope?.metrics.viewId == View.maybeOf(context)?.viewId
        ? scope?.metrics
        : null;
  }

  static ScreenSizeMetrics of(BuildContext context) {
    final metrics = maybeOf(context);
    if (metrics == null) {
      throw FlutterError(
        'No ScreenSizeAdapter surrounds this context in its FlutterView.',
      );
    }
    return metrics;
  }

  @override
  bool operator ==(Object other) =>
      other is ScreenSizeMetrics &&
      other.viewId == viewId &&
      other.originSize == originSize &&
      other.nativeDpr == nativeDpr &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(viewId, originSize, nativeDpr, scale);
}

/// Internal inherited storage; not exported by the package entry point.
class ScreenSizeMetricsScope extends InheritedWidget {
  const ScreenSizeMetricsScope({
    super.key,
    required this.metrics,
    required super.child,
  });
  final ScreenSizeMetrics metrics;

  @override
  bool updateShouldNotify(ScreenSizeMetricsScope oldWidget) =>
      oldWidget.metrics != metrics;
}
