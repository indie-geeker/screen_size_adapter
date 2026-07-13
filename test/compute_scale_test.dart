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

    test('copyWith can clear maxScale explicitly', () {
      const c1 = ScreenSizeAdapterConfig(
        designSize: Size(360, 690),
        maxScale: 2.0,
      );

      final c2 = c1.copyWith(clearMaxScale: true);

      expect(c2.maxScale, isNull);
    });

    test('copyWith can clear minScale explicitly', () {
      const c1 = ScreenSizeAdapterConfig(
        designSize: Size(360, 690),
        minScale: 0.8,
      );

      final c2 = c1.copyWith(clearMinScale: true);

      expect(c2.minScale, isNull);
    });

    test('copyWith rejects maxScale value when clearMaxScale is true', () {
      const c1 = ScreenSizeAdapterConfig(designSize: Size(360, 690));

      expect(
        () => c1.copyWith(maxScale: 2.0, clearMaxScale: true),
        throwsArgumentError,
      );
    });

    test('copyWith rejects minScale value when clearMinScale is true', () {
      const c1 = ScreenSizeAdapterConfig(designSize: Size(360, 690));

      expect(
        () => c1.copyWith(minScale: 0.8, clearMinScale: true),
        throwsArgumentError,
      );
    });

    test('copyWith rejects minScale greater than maxScale', () {
      const c1 = ScreenSizeAdapterConfig(designSize: Size(360, 690));

      expect(
        () => c1.copyWith(minScale: 2.0, maxScale: 1.0),
        throwsArgumentError,
      );
    });

    test('copyWith rejects inherited minScale greater than maxScale', () {
      const c1 = ScreenSizeAdapterConfig(
        designSize: Size(360, 690),
        minScale: 2.0,
      );

      expect(() => c1.copyWith(maxScale: 1.0), throwsArgumentError);
    });

    final invalidDesignSizes = <({String label, Size value})>[
      (label: 'zero width', value: const Size(0, 690)),
      (label: 'negative width', value: const Size(-1, 690)),
      (label: 'NaN width', value: const Size(double.nan, 690)),
      (label: 'infinite width', value: const Size(double.infinity, 690)),
      (label: 'zero height', value: const Size(360, 0)),
      (label: 'negative height', value: const Size(360, -1)),
      (label: 'NaN height', value: const Size(360, double.nan)),
      (label: 'infinite height', value: const Size(360, double.infinity)),
    ];

    for (final invalid in invalidDesignSizes) {
      test('copyWith rejects ${invalid.label}', () {
        const config = ScreenSizeAdapterConfig(designSize: Size(360, 690));

        expect(
          () => config.copyWith(designSize: invalid.value),
          throwsArgumentError,
        );
      });
    }

    test('copyWith rejects inherited invalid bounds', () {
      const invalidMin = ScreenSizeAdapterConfig(
        designSize: Size(360, 690),
        minScale: -1,
      );
      const invalidMax = ScreenSizeAdapterConfig(
        designSize: Size(360, 690),
        maxScale: double.infinity,
      );

      expect(() => invalidMin.copyWith(), throwsArgumentError);
      expect(() => invalidMax.copyWith(), throwsArgumentError);
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

    final invalidDesignSizes = <({String label, Size value})>[
      (label: 'zero width', value: const Size(0, 690)),
      (label: 'negative width', value: const Size(-1, 690)),
      (label: 'NaN width', value: const Size(double.nan, 690)),
      (label: 'infinite width', value: const Size(double.infinity, 690)),
      (label: 'zero height', value: const Size(360, 0)),
      (label: 'negative height', value: const Size(360, -1)),
      (label: 'NaN height', value: const Size(360, double.nan)),
      (label: 'infinite height', value: const Size(360, double.infinity)),
    ];

    for (final invalid in invalidDesignSizes) {
      test('rejects ${invalid.label} design size', () {
        expect(
          () => ScreenSizeAdapter.computeScale(
            origin: portraitOrigin,
            config: ScreenSizeAdapterConfig(designSize: invalid.value),
            isDesktop: false,
          ),
          throwsArgumentError,
        );
      });
    }

    final invalidBounds = <({String label, double value})>[
      (label: 'zero', value: 0),
      (label: 'negative', value: -1),
      (label: 'NaN', value: double.nan),
      (label: 'infinite', value: double.infinity),
    ];

    for (final invalid in invalidBounds) {
      test('rejects ${invalid.label} minScale', () {
        expect(
          () => ScreenSizeAdapter.computeScale(
            origin: portraitOrigin,
            config: ScreenSizeAdapterConfig(
              designSize: design,
              minScale: invalid.value,
            ),
            isDesktop: false,
          ),
          throwsArgumentError,
        );
      });

      test('rejects ${invalid.label} maxScale', () {
        expect(
          () => ScreenSizeAdapter.computeScale(
            origin: portraitOrigin,
            config: ScreenSizeAdapterConfig(
              designSize: design,
              maxScale: invalid.value,
            ),
            isDesktop: false,
          ),
          throwsArgumentError,
        );
      });
    }

    test('rejects invalid config before desktop scaling short-circuit', () {
      expect(
        () => ScreenSizeAdapter.computeScale(
          origin: const Size(1920, 1080),
          config: const ScreenSizeAdapterConfig(
            designSize: Size.zero,
            enableDesktopScaling: false,
          ),
          isDesktop: true,
        ),
        throwsArgumentError,
      );
    });

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
          maxScale: 2.0,
        ),
        isDesktop: false,
      );
      expect(s, 2.0);
    });

    test('default config does not clamp the scale (maxScale is null)', () {
      // Wide landscape on a 1280-wide canvas — without an explicit cap,
      // ScaleAxis.width follows origin.width / design.width unconditionally.
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
        origin: const Size(double.nan, 690),
        config: const ScreenSizeAdapterConfig(designSize: design),
        isDesktop: false,
      );
      expect(s, 1.0);
    });

    test('infinite raw scale falls back to 1.0', () {
      final s = ScreenSizeAdapter.computeScale(
        origin: const Size(double.infinity, 690),
        config: const ScreenSizeAdapterConfig(designSize: design),
        isDesktop: false,
      );
      expect(s, 1.0);
    });

    test('rejects minScale greater than maxScale', () {
      expect(
        () => ScreenSizeAdapter.computeScale(
          origin: const Size(360, 690),
          config: ScreenSizeAdapterConfig(
            designSize: const Size(360, 690),
            minScale: 2.0,
            maxScale: 1.0,
          ),
          isDesktop: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
