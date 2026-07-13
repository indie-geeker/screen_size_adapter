import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('SizedBox renders at design size on a 2x device', (tester) async {
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: const Size(720, 1380),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)), const Size(100, 50));
  });

  testWidgets('with maxScale clamp, SizedBox still measures at design size', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(
          designSize: Size(360, 690),
          maxScale: 1.5,
        ),
        simulatedDeviceSize: const Size(1440, 2760),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)), const Size(100, 50));
  });

  testWidgets(
    'isDesktop=true with enableDesktopScaling=false leaves layout raw',
    (tester) async {
      await tester.pumpWidget(
        ScreenSizeTestEnvironment(
          config: const ScreenSizeAdapterConfig(
            designSize: Size(360, 690),
            enableDesktopScaling: false,
          ),
          isDesktop: true,
          simulatedDeviceSize: const Size(1920, 1080),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: SizedBox(width: 100, height: 50)),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SizedBox)), const Size(100, 50));
    },
  );

  testWidgets('MediaQuery size and devicePixelRatio reflect scale', (
    tester,
  ) async {
    MediaQueryData? captured;
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: const Size(720, 1380),
        child: Builder(
          builder: (ctx) {
            captured = MediaQuery.of(ctx);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(captured!.size, const Size(360, 690));
    // simulated DPR comes from the test harness; assert relative scaling.
    expect(captured!.devicePixelRatio, greaterThan(1.0));
  });

  testWidgets('padding, viewPadding, viewInsets scale with the view', (
    tester,
  ) async {
    MediaQueryData? captured;
    await tester.pumpWidget(
      MediaQuery(
        // Inject a non-zero padding/inset so we can observe it being scaled.
        data: const MediaQueryData(
          size: Size(720, 1380),
          devicePixelRatio: 2.0,
          padding: EdgeInsets.only(top: 48, bottom: 24),
          viewPadding: EdgeInsets.only(top: 48, bottom: 24),
          viewInsets: EdgeInsets.only(bottom: 320),
          systemGestureInsets: EdgeInsets.only(left: 16, right: 16),
        ),
        child: ScreenSizeTestEnvironment(
          config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
          // No simulatedDeviceSize → reads parent MediaQuery size (720x1380),
          // scale becomes 2.0.
          child: Builder(
            builder: (ctx) {
              captured = MediaQuery.of(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(captured!.size, const Size(360, 690));
    expect(captured!.padding.top, 24);
    expect(captured!.padding.bottom, 12);
    expect(captured!.viewPadding.top, 24);
    expect(captured!.viewInsets.bottom, 160);
    expect(captured!.systemGestureInsets.left, 8);
  });

  testWidgets('rejects invalid design size during widget build', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ScreenSizeTestEnvironment(
        config: ScreenSizeAdapterConfig(designSize: Size.zero),
        child: SizedBox.shrink(),
      ),
    );

    expect(tester.takeException(), isArgumentError);
  });

  testWidgets('validates config before desktop scaling short-circuit', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ScreenSizeTestEnvironment(
        config: ScreenSizeAdapterConfig(
          designSize: Size(360, 690),
          enableDesktopScaling: false,
          minScale: -1,
        ),
        isDesktop: true,
        child: SizedBox.shrink(),
      ),
    );

    expect(tester.takeException(), isArgumentError);
  });
}
