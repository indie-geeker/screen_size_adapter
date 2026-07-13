import 'package:flutter/widgets.dart';

import 'config.dart';
import 'internal/scale_media_query.dart';
import 'screen_size_adapter_controller.dart';

/// Widget-test helper that mimics [ScreenSizeWidgetsFlutterBinding]'s
/// per-view scaling at the [MediaQuery] layer.
///
/// Use inside `testWidgets` (which uses `AutomatedTestWidgetsFlutterBinding`,
/// where the production binding is unavailable). Wraps [child] in a
/// [MediaQuery] whose `size` and inset/padding fields are divided by the
/// computed scale and whose `devicePixelRatio` is multiplied by it.
///
/// Scope mirrors `ScreenSizeAdapterScope`'s production behavior: `size`,
/// `devicePixelRatio`, `padding`, `viewPadding`, `viewInsets`, and
/// `systemGestureInsets`, gesture touch slop, and display-feature bounds all
/// reflect the per-view scale, so MediaQuery-dependent SafeArea, gesture,
/// foldable-layout, and keyboard-inset logic can be exercised in tests.
/// `textScaler` and other accessibility-related fields are passed through
/// unchanged.
///
/// This helper is intentionally **MediaQuery-only**. It does not replace the
/// automated test binding's root layout constraints. Use
/// [ScreenSizeTestViewport] when the assertion also depends on the adapted
/// viewport constraints.
///
/// Fidelity limit: neither helper installs a `RenderView`, creates an
/// engine-backed [FlutterView], proves root hit testing, nor executes the
/// production binding's pointer converter.
class ScreenSizeTestEnvironment extends StatelessWidget {
  /// Configuration to apply. Must include [ScreenSizeAdapterConfig.designSize].
  final ScreenSizeAdapterConfig config;

  /// Optional override for the simulated device size. Defaults to the
  /// enclosing [MediaQuery]'s size.
  final Size? simulatedDeviceSize;

  /// Whether to treat the simulated environment as desktop. Defaults to
  /// false. Combined with [ScreenSizeAdapterConfig.enableDesktopScaling] to
  /// determine whether scaling actually applies.
  final bool isDesktop;

  /// Subtree that runs under the simulated MediaQuery.
  final Widget child;

  const ScreenSizeTestEnvironment({
    required this.config,
    this.simulatedDeviceSize,
    this.isDesktop = false,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final actualSize = simulatedDeviceSize ?? mq.size;
    final scale = ScreenSizeAdapter.computeScale(
      origin: actualSize,
      config: config,
      isDesktop: isDesktop,
    );
    final base =
        simulatedDeviceSize == null ? mq : mq.copyWith(size: actualSize);
    return MediaQuery(data: scaleMediaQueryData(base, scale), child: child);
  }
}

/// Widget-test helper that aligns a wrapped subtree's layout constraints with
/// the adapted [MediaQuery] produced by [ScreenSizeTestEnvironment].
///
/// The subtree receives tight constraints equal to `originSize / scale`,
/// including when scale bounds mean that neither dimension equals the design
/// size. This is useful for layout assertions and overlay descendants whose
/// geometry depends on viewport constraints.
///
/// This remains a widget-test simulation: it does not install a `RenderView`,
/// create an engine-backed [FlutterView], prove root hit testing, or execute
/// the production binding's pointer converter.
class ScreenSizeTestViewport extends StatelessWidget {
  /// Configuration to apply. Must include [ScreenSizeAdapterConfig.designSize].
  final ScreenSizeAdapterConfig config;

  /// Optional override for the simulated device size. Defaults to the
  /// enclosing [MediaQuery]'s size.
  final Size? simulatedDeviceSize;

  /// Whether to treat the simulated environment as desktop.
  final bool isDesktop;

  /// Subtree that receives adapted MediaQuery metrics and tight viewport
  /// constraints.
  final Widget child;

  const ScreenSizeTestViewport({
    required this.config,
    this.simulatedDeviceSize,
    this.isDesktop = false,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenSizeTestEnvironment(
      config: config,
      simulatedDeviceSize: simulatedDeviceSize,
      isDesktop: isDesktop,
      child: Builder(
        builder: (context) {
          final adaptedSize = MediaQuery.sizeOf(context);
          return OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: adaptedSize.width,
            maxWidth: adaptedSize.width,
            minHeight: adaptedSize.height,
            maxHeight: adaptedSize.height,
            child: child,
          );
        },
      ),
    );
  }
}
