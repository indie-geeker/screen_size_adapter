part of '../screen_size_adapter.dart';

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

/// Runtime configuration for [screen_size_adapter].
class ScreenSizeAdapterConfig {
  final ScreenSizeTextScaleMode textScaleMode;

  /// Whether desktop platforms (Windows/macOS/Linux) should apply
  /// design-size scaling logic.
  ///
  /// Defaults to `false`, meaning desktop uses original window metrics.
  final bool enableDesktopScaling;

  /// Upper bound for the computed scale factor.
  ///
  /// When non-null, the scale is clamped so it never exceeds this value.
  /// Set to `null` to allow unlimited scaling.
  /// Defaults to `2.0`.
  final double? maxScale;

  const ScreenSizeAdapterConfig({
    this.textScaleMode = ScreenSizeTextScaleMode.design,
    this.enableDesktopScaling = false,
    this.maxScale = 2.0,
  });

  ScreenSizeAdapterConfig copyWith({
    ScreenSizeTextScaleMode? textScaleMode,
    bool? enableDesktopScaling,
    double? maxScale,
  }) {
    return ScreenSizeAdapterConfig(
      textScaleMode: textScaleMode ?? this.textScaleMode,
      enableDesktopScaling: enableDesktopScaling ?? this.enableDesktopScaling,
      maxScale: maxScale ?? this.maxScale,
    );
  }
}
