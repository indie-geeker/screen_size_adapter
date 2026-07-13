import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  late ScreenSizeWidgetsFlutterBinding binding;

  test('invalid config is rejected before binding installation', () {
    expect(
      () => ScreenSizeWidgetsFlutterBinding.ensureInitialized(
        const ScreenSizeAdapterConfig(designSize: Size.zero),
      ),
      throwsArgumentError,
    );
    expect(() => WidgetsBinding.instance, throwsFlutterError);
  });

  test('ensureInitialized installs and registers the primary view', () {
    binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
      const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );

    final primary = binding.platformDispatcher.implicitView;
    expect(primary, isNotNull);
    expect(binding.configForView(primary!)?.designSize, const Size(360, 690));
  });

  test('ensureInitialized is idempotent and replaces the primary config', () {
    final second = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
      const ScreenSizeAdapterConfig(
        designSize: Size(414, 896),
        scaleAxis: ScaleAxis.height,
      ),
    );

    expect(second, same(binding));
    final primary = second.platformDispatcher.implicitView;
    expect(primary, isNotNull);
    expect(second.configForView(primary!)?.designSize, const Size(414, 896));
    expect(second.configForView(primary)?.scaleAxis, ScaleAxis.height);
  });
}
