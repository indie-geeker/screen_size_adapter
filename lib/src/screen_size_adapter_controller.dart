import 'package:flutter/widgets.dart';

import 'config.dart';
import 'screen_size_widget_flutter_binding.dart';

/// Public runtime control APIs for screen adaptation.
///
/// Resolves the active view from [BuildContext] using [View.of], so each
/// call operates on the FlutterView that owns the calling widget — the
/// foundation for multi-view correctness.
class ScreenSizeAdapter {
  const ScreenSizeAdapter._();

  /// Pure: compute the scale factor given an origin size, config, and platform flag.
  /// Returns 1.0 when scaling should not apply (desktop without enableDesktopScaling),
  /// or when the raw value is non-finite / non-positive.
  static double computeScale({
    required Size origin,
    required ScreenSizeAdapterConfig config,
    required bool isDesktop,
  }) {
    final shouldApply = !isDesktop || config.enableDesktopScaling;
    if (!shouldApply) return 1.0;

    final widthScale = origin.width / config.designSize.width;
    final heightScale = origin.height / config.designSize.height;

    final raw = switch (config.scaleAxis) {
      ScaleAxis.width => widthScale,
      ScaleAxis.height => heightScale,
      ScaleAxis.shorter => widthScale < heightScale ? widthScale : heightScale,
      ScaleAxis.longer => widthScale > heightScale ? widthScale : heightScale,
    };

    if (raw.isNaN || raw.isInfinite || raw <= 0) return 1.0;

    var s = raw;
    if (config.minScale != null && s < config.minScale!) s = config.minScale!;
    if (config.maxScale != null && s > config.maxScale!) s = config.maxScale!;
    return s;
  }

  /// Update the design size for the [FlutterView] that owns [context].
  ///
  /// Throws [StateError] if no enclosing [View] exists (this only happens
  /// outside the widget tree, e.g. in custom test scaffolding without
  /// `runApp`).
  static void setDesignSize(BuildContext context, Size size) {
    final view = View.of(context);
    final binding =
        WidgetsBinding.instance as ScreenSizeWidgetsFlutterBinding;
    binding.updateView(view: view, designSize: size);
  }

  /// Reset the [FlutterView] that owns [context] to its current logical
  /// size — clears any in-app design-size override.
  static void reset(BuildContext context) {
    final view = View.of(context);
    final binding =
        WidgetsBinding.instance as ScreenSizeWidgetsFlutterBinding;
    binding.resetView(view: view);
  }

  /// Returns the most-recently-computed scale factor for the
  /// [FlutterView] that owns [context]. Returns `1.0` if the view has no
  /// registered configuration or has not yet undergone its first layout pass.
  static double scaleOf(BuildContext context) {
    final viewId = View.of(context).viewId;
    final binding =
        WidgetsBinding.instance as ScreenSizeWidgetsFlutterBinding;
    return binding.scaleForViewId(viewId) ?? 1.0;
  }
}
