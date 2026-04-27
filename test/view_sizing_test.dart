import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';
import 'package:screen_size_adapter/src/internal/view_sizing.dart';

void main() {
  group('ViewSizing.recompute', () {
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
          designSize: Size(360, 690),
          scaleAxis: ScaleAxis.width,
        ),
      );
      v.recompute(
        originSize: const Size(720, 1280),
        originDpr: 2.0,
        isDesktop: false,
      );
      expect(v.originSize, const Size(720, 1280));
      expect(v.scale, closeTo(2.0, 1e-9)); // 720/360 = 2.0 (no clamp by default)
      expect(v.effectiveDpr, closeTo(4.0, 1e-9)); // 2.0 * 2.0
    });

    test('recompute on desktop with scaling disabled returns identity', () {
      final v = ViewSizing(
        const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      );
      v.recompute(
        originSize: const Size(1920, 1080),
        originDpr: 1.0,
        isDesktop: true,
      );
      expect(v.scale, 1.0);
      expect(v.effectiveDpr, 1.0);
    });
  });
}
