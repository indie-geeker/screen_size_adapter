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
}

/// Runtime configuration for [screen_size_adapter].
class ScreenSizeAdapterConfig {
  final ScreenSizeTextScaleMode textScaleMode;

  /// Whether desktop platforms (Windows/macOS/Linux) should apply
  /// design-size scaling logic.
  ///
  /// Defaults to `false`, meaning desktop uses original window metrics.
  final bool enableDesktopScaling;

  const ScreenSizeAdapterConfig({
    this.textScaleMode = ScreenSizeTextScaleMode.legacyScale,
    this.enableDesktopScaling = false,
  });

  ScreenSizeAdapterConfig copyWith({
    ScreenSizeTextScaleMode? textScaleMode,
    bool? enableDesktopScaling,
  }) {
    return ScreenSizeAdapterConfig(
      textScaleMode: textScaleMode ?? this.textScaleMode,
      enableDesktopScaling: enableDesktopScaling ?? this.enableDesktopScaling,
    );
  }
}
