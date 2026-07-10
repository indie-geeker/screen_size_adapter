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
/// reflect the per-view scale, so SafeArea, gesture, foldable-layout, and
/// keyboard-inset logic behave the same in tests as in production.
/// `textScaler` and other accessibility-related fields are passed through
/// unchanged.
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
