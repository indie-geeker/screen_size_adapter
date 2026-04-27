import 'package:flutter/widgets.dart';

import 'config.dart';
import 'screen_size_adapter_controller.dart';

/// Widget-test helper that mimics [ScreenSizeWidgetsFlutterBinding]'s
/// per-view scaling at the [MediaQuery] layer.
///
/// Use inside `testWidgets` (which uses `AutomatedTestWidgetsFlutterBinding`,
/// where the production binding is unavailable). Wraps [child] in a
/// [MediaQuery] whose `size` is divided by the computed scale and whose
/// `devicePixelRatio` is multiplied by it — observably the same view
/// transformation the production binding performs.
class ScreenSizeTestEnvironment extends StatelessWidget {
  /// Configuration to apply. Must include [ScreenSizeAdapterConfig.designSize].
  final ScreenSizeAdapterConfig config;

  /// Optional override for the simulated device size. Defaults to the
  /// enclosing [MediaQuery]'s size.
  final Size? simulatedDeviceSize;

  /// Whether to treat the simulated environment as desktop. Defaults to
  /// false. Combined with [config.enableDesktopScaling] to determine
  /// whether scaling actually applies.
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
    return MediaQuery(
      data: mq.copyWith(
        size: actualSize / scale,
        devicePixelRatio: mq.devicePixelRatio * scale,
      ),
      child: child,
    );
  }
}
