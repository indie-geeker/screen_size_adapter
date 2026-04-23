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

  /// Lower bound for the computed scale factor.
  ///
  /// When non-null, the scale is clamped so it never falls below this value.
  /// Useful on small-screen phones or foldable cover displays where an
  /// unbounded scale < 1 can shrink text below legibility.
  /// Defaults to `null` (no lower bound) to preserve prior behavior.
  final double? minScale;

  const ScreenSizeAdapterConfig({
    this.textScaleMode = ScreenSizeTextScaleMode.design,
    this.enableDesktopScaling = false,
    this.maxScale = 2.0,
    this.minScale,
  }) : assert(
          minScale == null || maxScale == null || minScale <= maxScale,
          'minScale must be <= maxScale',
        );

  /// Creates a copy with the given fields replaced.
  ///
  /// To set [maxScale] to `null` (unlimited), use [copyWithMaxScale].
  /// To set [minScale] to `null` (remove floor), use [copyWithMinScale].
  ScreenSizeAdapterConfig copyWith({
    ScreenSizeTextScaleMode? textScaleMode,
    bool? enableDesktopScaling,
    double? maxScale,
    double? minScale,
  }) {
    return ScreenSizeAdapterConfig(
      textScaleMode: textScaleMode ?? this.textScaleMode,
      enableDesktopScaling: enableDesktopScaling ?? this.enableDesktopScaling,
      maxScale: maxScale ?? this.maxScale,
      minScale: minScale ?? this.minScale,
    );
  }

  /// Creates a copy with [maxScale] explicitly set (including `null` for unlimited).
  ScreenSizeAdapterConfig copyWithMaxScale(double? maxScale) {
    return ScreenSizeAdapterConfig(
      textScaleMode: textScaleMode,
      enableDesktopScaling: enableDesktopScaling,
      maxScale: maxScale,
      minScale: minScale,
    );
  }

  /// Creates a copy with [minScale] explicitly set (including `null` to remove the floor).
  ScreenSizeAdapterConfig copyWithMinScale(double? minScale) {
    return ScreenSizeAdapterConfig(
      textScaleMode: textScaleMode,
      enableDesktopScaling: enableDesktopScaling,
      maxScale: maxScale,
      minScale: minScale,
    );
  }
}
