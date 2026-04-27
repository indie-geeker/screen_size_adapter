import 'dart:ui' show Size;

/// Controls how [num.sp] values are transformed.
enum ScreenSizeTextScaleMode {
  /// Keeps the legacy behavior for backward compatibility.
  ///
  /// Formula: `sp = value * scale`.
  legacyScale,

  /// Keeps the design value unchanged.
  ///
  /// Formula: `sp = value`.
  design,

  /// Respects system accessibility text scaling.
  ///
  /// Formula: `sp = textScaler.scale(value)`.
  system,
}

/// Which axis the binding uses to derive the scale factor.
enum ScaleAxis {
  /// scale = origin.width / design.width — the historical default.
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

  /// Legacy text-scale mode. Will be removed in a follow-up task.
  final ScreenSizeTextScaleMode textScaleMode;

  const ScreenSizeAdapterConfig({
    required this.designSize,
    this.scaleAxis = ScaleAxis.width,
    this.textScaleMode = ScreenSizeTextScaleMode.design,
    this.enableDesktopScaling = false,
    this.maxScale = 2.0,
    this.minScale,
  }) : assert(
          minScale == null || maxScale == null || minScale <= maxScale,
          'minScale must be <= maxScale',
        );

  ScreenSizeAdapterConfig copyWith({
    Size? designSize,
    ScaleAxis? scaleAxis,
    ScreenSizeTextScaleMode? textScaleMode,
    bool? enableDesktopScaling,
    double? maxScale,
    double? minScale,
  }) {
    return ScreenSizeAdapterConfig(
      designSize: designSize ?? this.designSize,
      scaleAxis: scaleAxis ?? this.scaleAxis,
      textScaleMode: textScaleMode ?? this.textScaleMode,
      enableDesktopScaling: enableDesktopScaling ?? this.enableDesktopScaling,
      maxScale: maxScale ?? this.maxScale,
      minScale: minScale ?? this.minScale,
    );
  }

  ScreenSizeAdapterConfig copyWithMaxScale(double? maxScale) {
    return ScreenSizeAdapterConfig(
      designSize: designSize,
      scaleAxis: scaleAxis,
      textScaleMode: textScaleMode,
      enableDesktopScaling: enableDesktopScaling,
      maxScale: maxScale,
      minScale: minScale,
    );
  }

  ScreenSizeAdapterConfig copyWithMinScale(double? minScale) {
    return ScreenSizeAdapterConfig(
      designSize: designSize,
      scaleAxis: scaleAxis,
      textScaleMode: textScaleMode,
      enableDesktopScaling: enableDesktopScaling,
      maxScale: maxScale,
      minScale: minScale,
    );
  }
}
