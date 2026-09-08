import 'package:flutter/widgets.dart';

/// Immutable per-view values exposed by the production adapter scope.
/// Separate from MediaQuery so native size changes notify readers even when
/// the adapted MediaQuery remains identical.
class AdapterMetrics extends InheritedWidget {
  const AdapterMetrics({
    required this.viewId,
    required this.originSize,
    required this.scale,
    required super.child,
    super.key,
  });

  final int viewId;
  final Size originSize;
  final double scale;

  static AdapterMetrics? maybeOf(BuildContext context, int viewId) {
    final metrics =
        context.dependOnInheritedWidgetOfExactType<AdapterMetrics>();
    return metrics?.viewId == viewId ? metrics : null;
  }

  @override
  bool updateShouldNotify(AdapterMetrics oldWidget) =>
      viewId != oldWidget.viewId ||
      originSize != oldWidget.originSize ||
      scale != oldWidget.scale;
}
