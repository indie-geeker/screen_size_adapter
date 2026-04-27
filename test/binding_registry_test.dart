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

  tearDown(() {
    // Always re-register the primary view after each test so test order
    // doesn't matter. Cheap insurance for a public-API surface.
    final primary = binding.platformDispatcher.views.first;
    binding.attachView(view: primary, designSize: const Size(360, 690));
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

    test('resetView sets designSize to current view logical size', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(view: primary, designSize: const Size(100, 100));
      expect(binding.configForViewId(primary.viewId)?.designSize,
          const Size(100, 100));

      binding.resetView(view: primary);

      // After reset, designSize equals the view's current logical size
      // (physicalSize / devicePixelRatio).
      final expected = Size(
        primary.physicalSize.width / primary.devicePixelRatio,
        primary.physicalSize.height / primary.devicePixelRatio,
      );
      expect(binding.configForViewId(primary.viewId)?.designSize, expected);
    });

    test('resetView is a no-op for unregistered view', () {
      final primary = binding.platformDispatcher.views.first;
      binding.detachView(primary);
      // Should not throw, should not register anything new.
      binding.resetView(view: primary);
      expect(binding.configForViewId(primary.viewId), isNull);
      // Restore for downstream tests.
      binding.attachView(view: primary, designSize: const Size(360, 690));
    });
  });
}
