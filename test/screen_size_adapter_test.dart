import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
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

    test('desktop can opt into scaling with config', () {
      ScreenSizeHelper.initializeForTest(
        const Size(360, 640),
        logicalSize: const Size(1200, 800),
        isDesktop: true,
        config: const ScreenSizeAdapterConfig(enableDesktopScaling: true),
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
