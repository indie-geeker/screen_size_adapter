import 'dart:ui' show Size;

/// Which axis the binding uses to derive the scale factor.
enum ScaleAxis {
  /// scale = origin.width / design.width — applied unconditionally regardless
  /// of orientation. (0.3.x silently used origin.height / design.width in
  /// landscape on mobile; that implicit axis-swap is gone in 0.4.0. Use
  /// `ScaleAxis.shorter` if you want aspect-safe sizing across orientations.)
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

  /// Upper bound for the computed scale factor. `null` = unlimited (default
  /// since 0.5.0). Set explicitly to cap the scale on very large screens.
  final double? maxScale;

  /// Lower bound for the computed scale factor. `null` = no floor.
  final double? minScale;

  const ScreenSizeAdapterConfig({
    required this.designSize,
    this.scaleAxis = ScaleAxis.width,
    this.enableDesktopScaling = false,
    this.maxScale,
    this.minScale,
  }) : assert(
          minScale == null || maxScale == null || minScale <= maxScale,
          'minScale must be <= maxScale',
        );

  ScreenSizeAdapterConfig copyWith({
    Size? designSize,
    ScaleAxis? scaleAxis,
    bool? enableDesktopScaling,
    double? maxScale,
    double? minScale,
  }) {
    return ScreenSizeAdapterConfig(
      designSize: designSize ?? this.designSize,
      scaleAxis: scaleAxis ?? this.scaleAxis,
      enableDesktopScaling: enableDesktopScaling ?? this.enableDesktopScaling,
      maxScale: maxScale ?? this.maxScale,
      minScale: minScale ?? this.minScale,
    );
  }

  /// Creates a copy with [maxScale] explicitly set (including `null` for unlimited).
  ScreenSizeAdapterConfig copyWithMaxScale(double? maxScale) {
    return ScreenSizeAdapterConfig(
      designSize: designSize,
      scaleAxis: scaleAxis,
      enableDesktopScaling: enableDesktopScaling,
      maxScale: maxScale,
      minScale: minScale,
    );
  }

  /// Creates a copy with [minScale] explicitly set (including `null` to remove the floor).
  ScreenSizeAdapterConfig copyWithMinScale(double? minScale) {
    return ScreenSizeAdapterConfig(
      designSize: designSize,
      scaleAxis: scaleAxis,
      enableDesktopScaling: enableDesktopScaling,
      maxScale: maxScale,
      minScale: minScale,
    );
  }
}
