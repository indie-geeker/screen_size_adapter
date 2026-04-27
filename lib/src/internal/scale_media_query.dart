import 'package:flutter/widgets.dart';

/// Apply per-view scaling to a [MediaQueryData] so that downstream widgets
/// see sizes in design units instead of native logical pixels.
///
/// The binding's [createViewConfigurationFor] override only changes
/// `RenderView.configuration.devicePixelRatio` — that drives layout, but
/// `MediaQueryData.fromView(view)` reads `view.physicalSize /
/// view.devicePixelRatio` directly from the [FlutterView], bypassing the
/// override. This helper closes that gap.
///
/// Returns [data] unchanged when [scale] is 1.0.
MediaQueryData scaleMediaQueryData(MediaQueryData data, double scale) {
  if (scale == 1.0) return data;
  return data.copyWith(
    size: data.size / scale,
    devicePixelRatio: data.devicePixelRatio * scale,
    padding: data.padding / scale,
    viewPadding: data.viewPadding / scale,
    viewInsets: data.viewInsets / scale,
    systemGestureInsets: data.systemGestureInsets / scale,
  );
}
