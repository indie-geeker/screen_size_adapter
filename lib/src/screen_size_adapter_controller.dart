import 'package:flutter/widgets.dart';

import 'config.dart';
import 'internal/design_size_inherited.dart';
import 'screen_size_widget.dart';

/// Public runtime control APIs for screen adaptation.
class ScreenSizeAdapter {
  const ScreenSizeAdapter._();

  static ScreenSizeWidgetState of(BuildContext context) {
    return DesignSizeInheritedWidget.of(context);
  }

  static ScreenSizeWidgetState? maybeOf(BuildContext context) {
    return DesignSizeInheritedWidget.maybeOf(context);
  }

  /// Updates design size and triggers relayout for the current widget tree.
  static void setDesignSize(BuildContext context, Size size) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'No ScreenSizeWidget found in context. Make sure the app is initialized '
        'with ScreenSizeWidgetsFlutterBinding.ensureInitialized(...) before runApp().',
      );
    }
    state.setDesignSize(size);
  }

  /// Resets adapter state to current screen metrics and triggers relayout.
  static void reset(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'No ScreenSizeWidget found in context. Make sure the app is initialized '
        'with ScreenSizeWidgetsFlutterBinding.ensureInitialized(...) before runApp().',
      );
    }
    state.reset();
  }

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
      ScaleAxis.shorter =>
          widthScale < heightScale ? widthScale : heightScale,
      ScaleAxis.longer =>
          widthScale > heightScale ? widthScale : heightScale,
    };

    if (raw.isNaN || raw.isInfinite || raw <= 0) return 1.0;

    var s = raw;
    if (config.minScale != null && s < config.minScale!) s = config.minScale!;
    if (config.maxScale != null && s > config.maxScale!) s = config.maxScale!;
    return s;
  }
}
