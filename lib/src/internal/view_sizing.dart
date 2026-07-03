import 'package:flutter/widgets.dart';

import '../config.dart';
import '../screen_size_adapter_controller.dart';

/// Per-view sizing state held by the binding's registry.
///
/// Internal — not exported from the public API. Public name (no leading
/// underscore) so other internal files can import it across libraries.
class ViewSizing {
  ScreenSizeAdapterConfig config;
  Size originSize = Size.zero;
  double scale = 1.0;
  double effectiveDpr = 1.0;

  ViewSizing(this.config);

  void recompute({
    required Size originSize,
    required double originDpr,
    required bool isDesktop,
  }) {
    this.originSize = originSize;
    scale = ScreenSizeAdapter.computeScale(
      origin: originSize,
      config: config,
      isDesktop: isDesktop,
    );
    effectiveDpr = originDpr * scale;
  }
}
