import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  tearDown(ScreenSizeHelper.resetForTest);

  group('ScreenSizeHelper initializeForTest', () {
    test('initializes singleton without custom binding', () {
      ScreenSizeHelper.initializeForTest(const Size(360, 640));

      expect(ScreenSizeHelper.instance.designSize, const Size(360, 640));
      expect(ScreenSizeHelper.instance.scale, greaterThan(0));
      expect(ScreenSizeHelper.instance.isDesktop, isA<bool>());
    });

    test('dp/vw stay design-consistent in portrait', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(720, 1280),
        isDesktop: false,
      );

      expect(ScreenSizeHelper.instance.scale, closeTo(2.0, 0.0001));
      expect(100.dp, closeTo(100.0, 0.0001));
      expect(100.vw, closeTo(100.0, 0.0001));
      expect(100.vh, closeTo(100.0, 0.0001));
    });

    test('vh uses height ratio in landscape', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1280, 720),
        isDesktop: false,
      );

      // scale = 720 / 360 = 2
      // vh = 100 * (720 / 640) / 2 = 56.25
      expect(ScreenSizeHelper.instance.isLandscape, isTrue);
      expect(100.vh, closeTo(56.25, 0.0001));
    });

    test('vh uses independent height scaling in portrait', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(360, 780),
        isDesktop: false,
      );

      // scale = 360/360 = 1.0
      // vh = 100 * (780/640) / 1.0 = 121.875
      expect(ScreenSizeHelper.instance.scale, closeTo(1.0, 0.0001));
      expect(100.vh, closeTo(121.875, 0.001));
      // vw should still be 100
      expect(100.vw, closeTo(100.0, 0.0001));
    });

    test('sp follows configured text scale mode', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(720, 1280),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(
          textScaleMode: ScreenSizeTextScaleMode.legacyScale,
        ),
      );

      expect(14.sp, closeTo(28.0, 0.0001));

      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(720, 1280),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(
          textScaleMode: ScreenSizeTextScaleMode.design,
        ),
      );

      expect(14.sp, closeTo(14.0, 0.0001));
    });

    test('desktop disables scaling by default', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1200, 800),
        isDesktop: true,
      );

      expect(ScreenSizeHelper.instance.isDesktop, isTrue);
      expect(ScreenSizeHelper.instance.shouldApplyScale, isFalse);
      expect(ScreenSizeHelper.instance.scale, equals(1.0));
      expect(
        ScreenSizeHelper.instance.newMediaQueryData.size,
        const Size(1200, 800),
      );
      expect(100.dp, closeTo(100.0, 0.0001));
      expect(100.vw, closeTo(100.0, 0.0001));
      expect(100.vh, closeTo(100.0, 0.0001));
      expect(14.sp, closeTo(14.0, 0.0001));
    });

    test('scale is capped at maxScale on large screens', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1024, 768),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: 2.0),
      );

      // Raw scale would be 1024/360 = 2.844, should be capped at 2.0
      expect(ScreenSizeHelper.instance.scale, closeTo(2.0, 0.0001));
    });

    test('maxScale null allows unlimited scaling', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1024, 768),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: null),
      );

      // 1024 > 768 and isDesktop=false → landscape, scale = 768/360
      expect(ScreenSizeHelper.instance.scale, closeTo(768 / 360, 0.0001));
    });

    test('isLandscape getter agrees with setup landscape detection', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(844, 390),
        isDesktop: false,
      );

      expect(ScreenSizeHelper.instance.isLandscape, isTrue);
      // scale should use height (390) / designWidth (360)
      expect(ScreenSizeHelper.instance.scale, closeTo(390 / 360, 0.0001));
    });

    test('isLandscape is false for desktop even in wide window', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1200, 400),
        isDesktop: true,
        config: const ScreenSizeAdapterConfig(
          enableDesktopScaling: true,
          maxScale: null,
        ),
      );

      expect(ScreenSizeHelper.instance.isLandscape, isFalse);
      // Desktop should use width-based scale regardless of dimensions
      expect(ScreenSizeHelper.instance.scale, closeTo(1200 / 360, 0.0001));
    });

    test('sp default mode is design (returns raw value)', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(720, 1280),
        isDesktop: false,
      );

      // Default textScaleMode should now be 'design', so sp = value
      expect(14.sp, closeTo(14.0, 0.0001));
    });

    test('sp system mode respects textScaler', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 844),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(
          textScaleMode: ScreenSizeTextScaleMode.system,
        ),
      );

      // Default textScaler is 1.0, so sp = value * 1.0
      expect(14.sp, closeTo(14.0, 0.0001));
    });

    test('r uses min-dimension scaling', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 780),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: null),
      );

      // scale = 390/360 = 1.0833
      // widthScale = 390/360 = 1.0833
      // heightScale = 780/640 = 1.21875
      // minScale = 1.0833
      // r = 100 * 1.0833 / 1.0833 = 100.0
      expect(100.r, closeTo(100.0, 0.001));

      // On a device where height ratio < width ratio:
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(720, 800),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: null),
      );

      // scale = 720/360 = 2.0
      // widthScale = 720/360 = 2.0
      // heightScale = 800/640 = 1.25
      // minScale = 1.25
      // r = 100 * 1.25 / 2.0 = 62.5
      expect(100.r, closeTo(62.5, 0.001));
    });

    test('desktop can opt into scaling with config', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1200, 800),
        isDesktop: true,
        config: const ScreenSizeAdapterConfig(
          enableDesktopScaling: true,
          maxScale: null,
          textScaleMode: ScreenSizeTextScaleMode.legacyScale,
        ),
      );

      expect(ScreenSizeHelper.instance.isDesktop, isTrue);
      expect(ScreenSizeHelper.instance.shouldApplyScale, isTrue);
      expect(ScreenSizeHelper.instance.scale, closeTo(1200 / 360, 0.0001));
      expect(
        ScreenSizeHelper.instance.newMediaQueryData.size.width,
        closeTo(360.0, 0.0001),
      );
      expect(100.dp, closeTo(100.0, 0.0001));
      expect(14.sp, closeTo(14 * (1200 / 360), 0.0001));
    });

    test('scale is floored at minScale on small screens', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(240, 320),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(minScale: 0.8, maxScale: null),
      );

      // raw scale = 240/360 = 0.667 → clamped to 0.8
      expect(ScreenSizeHelper.instance.scale, closeTo(0.8, 1e-9));
    });

    test('minScale default null preserves old unclamped-below behavior', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(240, 320),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: null),
      );

      expect(ScreenSizeHelper.instance.scale, closeTo(240 / 360, 1e-9));
    });

    test('minScale copyWith threads through', () {
      const original = ScreenSizeAdapterConfig();
      final copied = original.copyWith(minScale: 0.5);
      expect(copied.minScale, 0.5);
      expect(copied.maxScale, original.maxScale);
    });

    test('minScale can be cleared to null via copyWithMinScale', () {
      const config = ScreenSizeAdapterConfig(minScale: 0.8, maxScale: null);
      final cleared = config.copyWithMinScale(null);
      expect(cleared.minScale, isNull);
      expect(cleared.maxScale, isNull);
    });
  });

  group('ScreenSizeHelper.computeScale (pure function)', () {
    const config = ScreenSizeAdapterConfig(maxScale: null);

    test('portrait: returns origin.width / design.width', () {
      expect(
        ScreenSizeHelper.computeScale(
          origin: const Size(720, 1280),
          design: const Size(360, 640),
          isDesktop: false,
          config: config,
        ),
        closeTo(2.0, 1e-9),
      );
    });

    test('landscape (mobile): uses origin.height / design.width', () {
      expect(
        ScreenSizeHelper.computeScale(
          origin: const Size(1280, 720),
          design: const Size(360, 640),
          isDesktop: false,
          config: config,
        ),
        closeTo(720 / 360, 1e-9),
      );
    });

    test('desktop without opt-in returns 1.0', () {
      expect(
        ScreenSizeHelper.computeScale(
          origin: const Size(1200, 800),
          design: const Size(360, 640),
          isDesktop: true,
          config: config,
        ),
        equals(1.0),
      );
    });

    test('desktop with enableDesktopScaling=true uses width ratio', () {
      expect(
        ScreenSizeHelper.computeScale(
          origin: const Size(1200, 800),
          design: const Size(360, 640),
          isDesktop: true,
          config: const ScreenSizeAdapterConfig(
            enableDesktopScaling: true,
            maxScale: null,
          ),
        ),
        closeTo(1200 / 360, 1e-9),
      );
    });

    test('degenerate inputs fall back to 1.0', () {
      expect(
        ScreenSizeHelper.computeScale(
          origin: const Size(0, 0),
          design: const Size(360, 640),
          isDesktop: false,
          config: config,
        ),
        equals(1.0),
      );
    });

    test('production setup() and pure function agree', () {
      // Since initializeForTest() internally delegates to computeScale, this
      // asserts the delegation path is wired (not an independent setup() vs.
      // computeScale comparison — that would require a real FlutterView).
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 844),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: null),
      );
      final computed = ScreenSizeHelper.computeScale(
        origin: const Size(390, 844),
        design: const Size(360, 640),
        isDesktop: false,
        config: const ScreenSizeAdapterConfig(maxScale: null),
      );
      expect(ScreenSizeHelper.instance.scale, closeTo(computed, 1e-12));
    });
  });

  group('ScreenSizeAdapter runtime control', () {
    testWidgets('setDesignSize updates design size and rebuilds subtree', (
      WidgetTester tester,
    ) async {
      ScreenSizeHelper.initializeForTest(const Size(360, 640));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenSizeWidget(
              child: Builder(
                builder: (BuildContext context) {
                  final width = ScreenSizeHelper.instance.designSize.width
                      .toStringAsFixed(0);
                  return Column(
                    children: [
                      Text('design:$width'),
                      TextButton(
                        onPressed: () {
                          ScreenSizeAdapter.setDesignSize(
                            context,
                            const Size(375, 667),
                          );
                        },
                        child: const Text('update'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('design:360'), findsOneWidget);

      await tester.tap(find.text('update'));
      await tester.pumpAndSettle();

      expect(find.text('design:375'), findsOneWidget);
      expect(ScreenSizeHelper.instance.designSize, const Size(375, 667));
    });

    testWidgets('maybeOf returns null outside ScreenSizeWidget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Text('${ScreenSizeAdapter.maybeOf(context) == null}');
            },
          ),
        ),
      );

      expect(find.text('true'), findsOneWidget);
    });
  });

  group('Safe-area inset preservation', () {
    test('copyWithScale does not scale padding, viewPadding, or viewInsets', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 844),
        isDesktop: false,
      );

      final original = MediaQueryData(
        size: const Size(390, 844),
        padding: const EdgeInsets.only(top: 47, bottom: 34),
        viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
        viewInsets: const EdgeInsets.only(bottom: 336),
      );

      final scaled = original.copyWithScale();

      // Insets should be preserved exactly
      expect(scaled.padding, original.padding);
      expect(scaled.viewPadding, original.viewPadding);
      expect(scaled.viewInsets, original.viewInsets);

      // Size should be scaled
      expect(scaled.size.width, closeTo(390 / ScreenSizeHelper.instance.scale, 0.1));
    });
  });

  group('Screen fraction extensions', () {
    test('sw returns fraction of scaled screen width', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 844),
        isDesktop: false,
      );

      final scaledWidth = ScreenSizeHelper.instance.newMediaQueryData.size.width;
      expect(0.5.sw, closeTo(scaledWidth * 0.5, 0.001));
      expect(1.0.sw, closeTo(scaledWidth, 0.001));
    });

    test('sh returns fraction of scaled screen height', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 844),
        isDesktop: false,
      );

      final scaledHeight = ScreenSizeHelper.instance.newMediaQueryData.size.height;
      expect(0.5.sh, closeTo(scaledHeight * 0.5, 0.001));
      expect(1.0.sh, closeTo(scaledHeight, 0.001));
    });
  });

  group('Convenience extensions', () {
    setUp(() {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(390, 844),
        isDesktop: false,
      );
    });

    test('verticalSpace returns SizedBox with adapted height', () {
      final SizedBox widget = 16.verticalSpace;
      expect(widget.height, closeTo(16.dp, 0.001));
      expect(widget.width, isNull);
    });

    test('horizontalSpace returns SizedBox with adapted width', () {
      final SizedBox widget = 16.horizontalSpace;
      expect(widget.width, closeTo(16.dp, 0.001));
      expect(widget.height, isNull);
    });

    test('EdgeInsets.w scales all edges by dp', () {
      final insets = const EdgeInsets.only(left: 8, top: 16, right: 8, bottom: 24).w;
      expect(insets.left, closeTo(8.dp, 0.001));
      expect(insets.top, closeTo(16.dp, 0.001));
      expect(insets.right, closeTo(8.dp, 0.001));
      expect(insets.bottom, closeTo(24.dp, 0.001));
    });

    test('EdgeInsets.r scales all edges by r', () {
      final insets = const EdgeInsets.all(10).r;
      expect(insets.left, closeTo(10.r, 0.001));
      expect(insets.top, closeTo(10.r, 0.001));
    });

    test('BorderRadius.w scales all corners by dp', () {
      final radius = BorderRadius.circular(16).w;
      expect(radius.topLeft.x, closeTo(16.dp, 0.001));
      expect(radius.bottomRight.x, closeTo(16.dp, 0.001));
    });

    test('BorderRadius.r scales all corners by r', () {
      final radius = BorderRadius.circular(16).r;
      expect(radius.topLeft.x, closeTo(16.r, 0.001));
      expect(radius.bottomRight.x, closeTo(16.r, 0.001));
    });
  });

  group('Uninitialized fallback', () {
    test('isReady is true after initializeForTest', () {
      ScreenSizeHelper.initializeForTest(const Size(360, 640));
      expect(ScreenSizeHelper.isReady, isTrue);
    });

    test('maybeInstance returns non-null after init', () {
      ScreenSizeHelper.initializeForTest(const Size(360, 640));
      expect(ScreenSizeHelper.maybeInstance, isNotNull);
    });

    test('extensions return raw value when helper is ready and identity-scaled', () {
      // With a ready helper and identity scaling, extensions should return
      // the raw value. This also exercises the maybeInstance null-safe
      // code path under normal conditions.
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(360, 640),
        isDesktop: false,
      );
      expect(ScreenSizeHelper.isReady, isTrue);
      expect(42.dp, closeTo(42.0, 1e-9));
      expect(42.vw, closeTo(42.0, 1e-9));
      expect(42.vh, closeTo(42.0, 1e-9));
      expect(42.r, closeTo(42.0, 1e-9));
    });

    test('isReady is false and maybeInstance is null after resetForTest', () {
      ScreenSizeHelper.initializeForTest(const Size(360, 640));
      expect(ScreenSizeHelper.isReady, isTrue);
      ScreenSizeHelper.resetForTest();
      expect(ScreenSizeHelper.isReady, isFalse);
      expect(ScreenSizeHelper.maybeInstance, isNull);
    });

    test('extensions return raw toDouble() when helper is absent', () {
      ScreenSizeHelper.resetForTest();
      expect(ScreenSizeHelper.maybeInstance, isNull);
      expect(42.dp, closeTo(42.0, 1e-12));
      expect(42.vw, closeTo(42.0, 1e-12));
      expect(42.vh, closeTo(42.0, 1e-12));
      expect(42.sp, closeTo(42.0, 1e-12));
      expect(42.r, closeTo(42.0, 1e-12));
      expect(0.5.sw, closeTo(0.5, 1e-12));
      expect(0.5.sh, closeTo(0.5, 1e-12));
    });
  });

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
}
