import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  late ScreenSizeWidgetsFlutterBinding binding;
  setUpAll(() {
    binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
      const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );
  });

  tearDown(() {
    // Always re-register the primary view after each test so test order
    // doesn't matter. Cheap insurance for a public-API surface.
    final primary = binding.platformDispatcher.views.first;
    binding.attachView(
      view: primary,
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );
  });

  group('Part C: binding registry', () {
    test('typed instance getter returns the installed adapter binding', () {
      expect(ScreenSizeWidgetsFlutterBinding.instance, same(binding));
    });

    test('ensureInitialized registers primary view', () {
      final primary = binding.platformDispatcher.views.first;
      expect(binding.scaleForView(primary), isNotNull);
    });

    test('attachView replaces config; detachView removes it', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(
          designSize: Size(800, 600),
          scaleAxis: ScaleAxis.shorter,
        ),
      );
      expect(binding.scaleForView(primary), isNotNull);
      expect(binding.configForView(primary)?.designSize, const Size(800, 600));
      expect(binding.configForView(primary)?.scaleAxis, ScaleAxis.shorter);

      binding.detachView(primary);
      expect(binding.scaleForView(primary), isNull);

      // Re-register so subsequent tests in this file have a primary view.
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
    });

    test('attachView rejects non-positive design sizes and scale bounds', () {
      final primary = binding.platformDispatcher.views.first;

      expect(
        () => binding.attachView(
          view: primary,
          config: const ScreenSizeAdapterConfig(designSize: Size.zero),
        ),
        throwsArgumentError,
      );
      expect(
        () => binding.attachView(
          view: primary,
          config: const ScreenSizeAdapterConfig(
            designSize: Size(360, 690),
            minScale: 0,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => binding.attachView(
          view: primary,
          config: const ScreenSizeAdapterConfig(
            designSize: Size(360, 690),
            maxScale: -1,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('updateView replaces config with complete config', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(
          designSize: Size(360, 690),
          scaleAxis: ScaleAxis.height,
        ),
      );
      binding.updateView(
        view: primary,
        config: const ScreenSizeAdapterConfig(
          designSize: Size(414, 896),
          scaleAxis: ScaleAxis.shorter,
        ),
      );
      expect(binding.configForView(primary)?.designSize, const Size(414, 896));
      expect(binding.configForView(primary)?.scaleAxis, ScaleAxis.shorter);
    });

    test('updateView rejects invalid replacement config values', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );

      expect(
        () => binding.updateView(
          view: primary,
          config: const ScreenSizeAdapterConfig(designSize: Size.zero),
        ),
        throwsArgumentError,
      );
      expect(
        () => binding.updateView(
          view: primary,
          config: const ScreenSizeAdapterConfig(
            designSize: Size(360, 690),
            minScale: 0,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => binding.updateView(
          view: primary,
          config: const ScreenSizeAdapterConfig(
            designSize: Size(360, 690),
            maxScale: -1,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('updateView throws if view not registered', () {
      // Build a stand-in: detach to make the primary unregistered, then update.
      final primary = binding.platformDispatcher.views.first;
      binding.detachView(primary);
      expect(
        () => binding.updateView(
          view: primary,
          config: const ScreenSizeAdapterConfig(designSize: Size(1, 1)),
        ),
        throwsA(isA<StateError>()),
      );
      // Restore for downstream tests.
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
    });

    test('scaleForView returns null for unmanaged views', () {
      final primary = binding.platformDispatcher.views.first;
      binding.detachView(primary);
      expect(binding.scaleForView(primary), isNull);
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
    });

    test('configForView returns null for unmanaged views', () {
      final primary = binding.platformDispatcher.views.first;
      binding.detachView(primary);
      expect(binding.configForView(primary), isNull);
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
    });

    test('resetView sets designSize to current view logical size', () {
      final primary = binding.platformDispatcher.views.first;
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(100, 100)),
      );
      expect(binding.configForView(primary)?.designSize, const Size(100, 100));

      binding.resetView(view: primary);

      // After reset, designSize equals the view's current logical size
      // (physicalSize / devicePixelRatio).
      final expected = Size(
        primary.physicalSize.width / primary.devicePixelRatio,
        primary.physicalSize.height / primary.devicePixelRatio,
      );
      expect(binding.configForView(primary)?.designSize, expected);
    });

    test('resetView is a no-op for unregistered view', () {
      final primary = binding.platformDispatcher.views.first;
      binding.detachView(primary);
      // Should not throw, should not register anything new.
      binding.resetView(view: primary);
      expect(binding.configForView(primary), isNull);
      // Restore for downstream tests.
      binding.attachView(
        view: primary,
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
    });
  });

  group('Part C: ScreenSizeAdapter facade', () {
    // NOTE: testWidgets requires AutomatedTestWidgetsFlutterBinding which is
    // incompatible with our ScreenSizeWidgetsFlutterBinding. We bootstrap a
    // minimal widget tree directly via binding.attachRootWidget so the
    // facade methods can resolve View.of(context) against our concrete
    // binding and registry.
    test('setDesignSize updates the registry for the enclosing view', () async {
      BuildContext? captured;
      final primary = binding.platformDispatcher.views.first;
      binding.attachRootWidget(
        View(
          view: primary,
          child: Builder(
            builder: (ctx) {
              captured = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      binding.scheduleWarmUpFrame();
      await Future<void>.delayed(Duration.zero);

      ScreenSizeAdapter.setDesignSize(captured!, const Size(414, 896));
      final view = View.of(captured!);
      expect(binding.configForView(view)?.designSize, const Size(414, 896));
    });

    test(
      'scaleOf returns the registered scale (or 1.0 if unmanaged)',
      () async {
        BuildContext? captured;
        final primary = binding.platformDispatcher.views.first;
        binding.attachRootWidget(
          View(
            view: primary,
            child: Builder(
              builder: (ctx) {
                captured = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        binding.scheduleWarmUpFrame();
        await Future<void>.delayed(Duration.zero);

        final scale = ScreenSizeAdapter.scaleOf(captured!);
        expect(scale, isNonZero);
      },
    );
  });
}
