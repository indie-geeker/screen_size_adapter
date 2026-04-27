import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';
import 'package:screen_size_adapter/src/internal/view_sizing.dart';

void main() {
  testWidgets('ensureInitialized fails after test binding is created', (
    WidgetTester tester,
  ) async {
    expect(
      () => ScreenSizeWidgetsFlutterBinding.ensureInitialized(
        const Size(360, 640),
      ),
      throwsA(isA<StateError>()),
    );
  });

  group('Part C: ScreenSizeAdapterConfig new fields', () {
    test('designSize is required and stored', () {
      const config = ScreenSizeAdapterConfig(designSize: Size(360, 690));
      expect(config.designSize, const Size(360, 690));
    });

    test('scaleAxis defaults to width', () {
      const config = ScreenSizeAdapterConfig(designSize: Size(360, 690));
      expect(config.scaleAxis, ScaleAxis.width);
    });

    test('scaleAxis is configurable', () {
      const config = ScreenSizeAdapterConfig(
        designSize: Size(360, 690),
        scaleAxis: ScaleAxis.shorter,
      );
      expect(config.scaleAxis, ScaleAxis.shorter);
    });

    test('copyWith preserves designSize and scaleAxis', () {
      const c1 = ScreenSizeAdapterConfig(
        designSize: Size(360, 690), scaleAxis: ScaleAxis.height,
      );
      final c2 = c1.copyWith(maxScale: 3.0);
      expect(c2.designSize, const Size(360, 690));
      expect(c2.scaleAxis, ScaleAxis.height);
      expect(c2.maxScale, 3.0);
    });

    test('copyWith can replace designSize', () {
      const c1 = ScreenSizeAdapterConfig(designSize: Size(360, 690));
      final c2 = c1.copyWith(designSize: const Size(414, 896));
      expect(c2.designSize, const Size(414, 896));
    });

    test('ScaleAxis enum has 4 values', () {
      expect(ScaleAxis.values, [
        ScaleAxis.width, ScaleAxis.height, ScaleAxis.shorter, ScaleAxis.longer,
      ]);
    });
  });

  group('Part C: ScreenSizeAdapter.computeScale', () {
    const portraitOrigin = Size(720, 1280);
    const landscapeOrigin = Size(1280, 720);
    const design = Size(360, 690);

    test('width axis: scale = origin.w / design.w', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: portraitOrigin,
        config: const ScreenSizeAdapterConfig(designSize: design, scaleAxis: ScaleAxis.width),
        isDesktop: false,
      );
      expect(s, closeTo(720 / 360, 1e-9));
    });

    test('height axis: scale = origin.h / design.h', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: portraitOrigin,
        config: const ScreenSizeAdapterConfig(designSize: design, scaleAxis: ScaleAxis.height),
        isDesktop: false,
      );
      expect(s, closeTo(1280 / 690, 1e-9));
    });

    test('shorter axis on landscape picks height', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: landscapeOrigin,
        config: const ScreenSizeAdapterConfig(designSize: design, scaleAxis: ScaleAxis.shorter),
        isDesktop: false,
      );
      // 1280/360 = 3.55, 720/690 = 1.04 -> shorter wins (1.04). Under default maxScale=2.0.
      expect(s, closeTo(720 / 690, 1e-9));
    });

    test('longer axis on landscape picks width then clamps to maxScale', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: landscapeOrigin,
        config: const ScreenSizeAdapterConfig(designSize: design, scaleAxis: ScaleAxis.longer),
        isDesktop: false,
      );
      // 1280/360 ~= 3.55 clamped to 2.0
      expect(s, 2.0);
    });

    test('minScale floors a scale below 1 on a small device', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(180, 320),
        config: const ScreenSizeAdapterConfig(designSize: design, minScale: 0.8),
        isDesktop: false,
      );
      expect(s, 0.8);
    });

    test('isDesktop with enableDesktopScaling=false short-circuits to 1.0', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(1920, 1080),
        config: const ScreenSizeAdapterConfig(designSize: design, enableDesktopScaling: false),
        isDesktop: true,
      );
      expect(s, 1.0);
    });

    test('isDesktop with enableDesktopScaling=true applies scaleAxis', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(1920, 1080),
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          enableDesktopScaling: true,
          scaleAxis: ScaleAxis.width,
          maxScale: null,
        ),
        isDesktop: true,
      );
      expect(s, closeTo(1920 / 360, 1e-9));
    });

    test('non-positive raw scale falls back to 1.0', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(0, 0),
        config: const ScreenSizeAdapterConfig(designSize: design),
        isDesktop: false,
      );
      expect(s, 1.0);
    });

    test('NaN raw scale falls back to 1.0', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(0, 0),
        config: const ScreenSizeAdapterConfig(designSize: Size(0, 0)),
        isDesktop: false,
      );
      // 0/0 = NaN
      expect(s, 1.0);
    });

    test('infinite raw scale falls back to 1.0', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(360, 690),
        config: const ScreenSizeAdapterConfig(designSize: Size(0, 0)),
        isDesktop: false,
      );
      // 360/0 = infinity
      expect(s, 1.0);
    });
  });

  group('Part C: ViewSizing.recompute', () {
    test('initial state has scale 1.0 and zero size', () {
      final v = ViewSizing(
        const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
      expect(v.scale, 1.0);
      expect(v.originSize, Size.zero);
      expect(v.effectiveDpr, 1.0);
    });

    test('recompute populates fields and applies scaleAxis', () {
      final v = ViewSizing(
        const ScreenSizeAdapterConfig(
          designSize: Size(360, 690), scaleAxis: ScaleAxis.width,
        ),
      );
      v.recompute(originSize: const Size(720, 1280), originDpr: 2.0, isDesktop: false);
      expect(v.originSize, const Size(720, 1280));
      expect(v.scale, closeTo(2.0, 1e-9));         // 720/360 clamped to maxScale 2.0
      expect(v.effectiveDpr, closeTo(4.0, 1e-9));  // 2.0 originDpr * 2.0 scale
    });

    test('recompute on desktop with scaling disabled returns identity', () {
      final v = ViewSizing(
        const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
      v.recompute(originSize: const Size(1920, 1080), originDpr: 1.0, isDesktop: true);
      expect(v.scale, 1.0);
      expect(v.effectiveDpr, 1.0);
    });
  });
}
