import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  late ScreenSizeWidgetsFlutterBinding binding;
  setUpAll(() {
    binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
      const Size(360, 690),
    ) as ScreenSizeWidgetsFlutterBinding;
  });

  group('Part C: binding registry', () {
    test('ensureInitialized registers primary view', () {
      final primaryViewId = binding.platformDispatcher.views.first.viewId;
      expect(binding.scaleForViewId(primaryViewId), isNotNull);
    });

    test('attachView replaces config; detachView removes it', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(
        view: primary,
        designSize: const Size(800, 600),
        scaleAxis: ScaleAxis.shorter,
      );
      expect(binding.scaleForViewId(primary.viewId), isNotNull);
      expect(binding.configForViewId(primary.viewId)?.designSize,
          const Size(800, 600));
      expect(binding.configForViewId(primary.viewId)?.scaleAxis,
          ScaleAxis.shorter);

      binding.detachView(primary);
      expect(binding.scaleForViewId(primary.viewId), isNull);

      // Re-register so subsequent tests in this file have a primary view.
      binding.attachView(
        view: primary,
        designSize: const Size(360, 690),
      );
    });

    test('updateView mutates designSize without losing other config', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(
        view: primary,
        designSize: const Size(360, 690),
        scaleAxis: ScaleAxis.height,
      );
      binding.updateView(view: primary, designSize: const Size(414, 896));
      expect(binding.configForViewId(primary.viewId)?.designSize,
          const Size(414, 896));
      expect(binding.configForViewId(primary.viewId)?.scaleAxis,
          ScaleAxis.height);
    });

    test('updateView throws if view not registered', () {
      // Build a stand-in: detach to make the primary unregistered, then update.
      final primary = binding.platformDispatcher.views.first;
      binding.detachView(primary);
      expect(
        () => binding.updateView(view: primary, designSize: const Size(1, 1)),
        throwsA(isA<StateError>()),
      );
      // Restore for downstream tests.
      binding.attachView(view: primary, designSize: const Size(360, 690));
    });

    test('scaleForViewId returns null for unmanaged views', () {
      expect(binding.scaleForViewId(99999), isNull);
    });

    test('configForViewId returns null for unmanaged views', () {
      expect(binding.configForViewId(99999), isNull);
    });
  });
}
