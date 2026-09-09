import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Apply per-view scaling to a [MediaQueryData] so that downstream widgets
/// see sizes in design units instead of native logical pixels.
///
/// Root layout uses design units; global input and gesture thresholds stay in
/// native logical units. Image density includes the render scale. User text
/// scaling and all non-geometric environment preferences are preserved.
///
/// Returns [data] unchanged when [scale] is 1.0.
MediaQueryData scaleMediaQueryData(MediaQueryData data, double scale) {
  if (scale == 1.0) return data;
  return data.copyWith(
    size: data.size / scale,
    devicePixelRatio: data.devicePixelRatio * scale,
    // Flutter's default native selection anchor mixes local and global units
    // under ancestor scaling. Keep the existing Flutter-menu policy until the
    // SDK path is fixed; this does not fix native caret/selection geometry.
    supportsShowingSystemContextMenu: false,
    padding: data.padding / scale,
    viewPadding: data.viewPadding / scale,
    viewInsets: data.viewInsets / scale,
    systemGestureInsets: data.systemGestureInsets / scale,
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
