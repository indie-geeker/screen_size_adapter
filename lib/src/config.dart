import 'dart:ui' show Size;

import 'internal/config_validation.dart';

/// Which axis the binding uses to derive the scale factor.
enum ScaleAxis {
  /// scale = origin.width / design.width, applied unconditionally regardless
  /// of orientation. Use `ScaleAxis.shorter` if you want aspect-safe sizing
  /// across orientations.
  width,

  /// scale = origin.height / design.height.
  height,

  /// scale = min(origin.w / design.w, origin.h / design.h).
  /// Use this when you want aspect-safe sizing (circles stay circular).
  shorter,

  /// scale = max(origin.w / design.w, origin.h / design.h).
  longer,
}

/// Runtime configuration for [screen_size_adapter].
class ScreenSizeAdapterConfig {
  /// Design canvas the app was authored against. Plain numbers in widget code
  /// are interpreted in these units after the binding scales the view.
  final Size designSize;

  /// Which axis the binding uses to derive the scale. See [ScaleAxis].
  final ScaleAxis scaleAxis;

  /// Whether desktop platforms (Windows/macOS/Linux) apply scaling at all.
  /// Defaults to false: desktop windows use their native logical size.
  final bool enableDesktopScaling;

  /// Upper bound for the computed scale factor. `null` = unlimited.
  final double? maxScale;

  /// Lower bound for the computed scale factor. `null` = no floor.
  final double? minScale;

  const ScreenSizeAdapterConfig({
    required this.designSize,
    this.scaleAxis = ScaleAxis.width,
    this.enableDesktopScaling = false,
    this.maxScale,
    this.minScale,
  });

  ScreenSizeAdapterConfig copyWith({
    Size? designSize,
    ScaleAxis? scaleAxis,
    bool? enableDesktopScaling,
    double? maxScale,
    double? minScale,
    bool clearMaxScale = false,
    bool clearMinScale = false,
  }) {
    if (clearMaxScale && maxScale != null) {
      throw ArgumentError.value(
        maxScale,
        'maxScale',
        'cannot be provided when clearMaxScale is true',
      );
    }
    if (clearMinScale && minScale != null) {
      throw ArgumentError.value(
        minScale,
        'minScale',
        'cannot be provided when clearMinScale is true',
      );
    }
    final nextMaxScale = clearMaxScale ? null : maxScale ?? this.maxScale;
    final nextMinScale = clearMinScale ? null : minScale ?? this.minScale;
    validateScaleBounds(minScale: nextMinScale, maxScale: nextMaxScale);

    return ScreenSizeAdapterConfig(
      designSize: designSize ?? this.designSize,
      scaleAxis: scaleAxis ?? this.scaleAxis,
      enableDesktopScaling: enableDesktopScaling ?? this.enableDesktopScaling,
      maxScale: nextMaxScale,
      minScale: nextMinScale,
    );
  }
}
