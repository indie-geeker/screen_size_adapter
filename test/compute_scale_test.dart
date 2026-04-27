import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  group('ScreenSizeAdapterConfig fields', () {
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
        designSize: Size(360, 690),
        scaleAxis: ScaleAxis.height,
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
        ScaleAxis.width,
        ScaleAxis.height,
        ScaleAxis.shorter,
        ScaleAxis.longer,
      ]);
    });
  });

  group('ScreenSizeAdapter.computeScale', () {
    const portraitOrigin = Size(720, 1280);
    const landscapeOrigin = Size(1280, 720);
    const design = Size(360, 690);

    test('width axis: scale = origin.w / design.w', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: portraitOrigin,
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          scaleAxis: ScaleAxis.width,
        ),
        isDesktop: false,
      );
      expect(s, closeTo(720 / 360, 1e-9));
    });

    test('height axis: scale = origin.h / design.h', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: portraitOrigin,
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          scaleAxis: ScaleAxis.height,
        ),
        isDesktop: false,
      );
      expect(s, closeTo(1280 / 690, 1e-9));
    });

    test('shorter axis on landscape picks height', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: landscapeOrigin,
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          scaleAxis: ScaleAxis.shorter,
        ),
        isDesktop: false,
      );
      // 1280/360 = 3.55, 720/690 = 1.04 -> shorter wins (1.04).
      expect(s, closeTo(720 / 690, 1e-9));
    });

    test('longer axis on landscape picks width then clamps to maxScale', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: landscapeOrigin,
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          scaleAxis: ScaleAxis.longer,
          maxScale: 2.0, // explicit since 0.5.0 (no default cap)
        ),
        isDesktop: false,
      );
      expect(s, 2.0);
    });

    test('default config does not clamp the scale (maxScale is null)', () {
      // Wide landscape on a 1280-wide canvas — without an explicit cap,
      // ScaleAxis.width follows origin.width / design.width unconditionally.
      // Pre-0.5.0 this would have clamped to 2.0.
      final s = ScreenSizeAdapter.computeScale(
        origin: landscapeOrigin,
        config: const ScreenSizeAdapterConfig(designSize: design),
        isDesktop: false,
      );
      expect(s, closeTo(landscapeOrigin.width / design.width, 1e-9));
      expect(s, greaterThan(2.0));
    });

    test('minScale floors a scale below 1 on a small device', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(180, 320),
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          minScale: 0.8,
        ),
        isDesktop: false,
      );
      expect(s, 0.8);
    });

    test('isDesktop with enableDesktopScaling=false short-circuits to 1.0', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(1920, 1080),
        config: const ScreenSizeAdapterConfig(
          designSize: design,
          enableDesktopScaling: false,
        ),
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
}
