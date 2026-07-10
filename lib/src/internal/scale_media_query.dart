import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/widgets.dart';

/// Apply per-view scaling to a [MediaQueryData] so that downstream widgets
/// see sizes in design units instead of native logical pixels.
///
/// The binding's [createViewConfigurationFor] override only changes
/// `RenderView.configuration.devicePixelRatio` — that drives layout, but
/// `MediaQueryData.fromView(view)` reads `view.physicalSize /
/// view.devicePixelRatio` directly from the [FlutterView], bypassing the
/// override. This helper closes that gap for size, insets, gesture thresholds,
/// and display-feature coordinates.
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
    gestureSettings:
        data.gestureSettings.touchSlop == null
            ? data.gestureSettings
            : DeviceGestureSettings(
              touchSlop: data.gestureSettings.touchSlop! / scale,
            ),
    displayFeatures: [
      for (final feature in data.displayFeatures)
        ui.DisplayFeature(
          bounds: ui.Rect.fromLTRB(
            feature.bounds.left / scale,
            feature.bounds.top / scale,
            feature.bounds.right / scale,
            feature.bounds.bottom / scale,
          ),
          type: feature.type,
          state: feature.state,
        ),
    ],
  );
}
