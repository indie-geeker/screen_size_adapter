import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'root_viewport_test.dart' show nativeView;

void main() {
  testWidgets('Windows scaling is opt-in and scoped to widget configuration', (
    tester,
  ) async {
    nativeView(tester);
    var desktopScaling = false;
    late StateSetter rebuild;
    late ScreenSizeMetrics metrics;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return ScreenSizeAdapter(
            config: ScreenSizeAdapterConfig(
              designSize: const Size(400, 300),
              enableDesktopScaling: desktopScaling,
            ),
            child: Builder(
              builder: (context) {
                metrics = ScreenSizeAdapter.of(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(metrics.scale, 1);
    expect(metrics.designSize, const Size(800, 600));
    rebuild(() => desktopScaling = true);
    await tester.pump();
    expect(metrics.scale, 2);
    expect(metrics.designSize, const Size(400, 300));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'disabled adapter bypasses clamps and preserves input and routes',
    (tester) async {
      nativeView(tester);
      var enabled = true;
      late StateSetter rebuild;
      late ScreenSizeMetrics metrics;
      final controller = TextEditingController(text: 'keep me');
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return ScreenSizeAdapter(
              enabled: enabled,
              config: const ScreenSizeAdapterConfig(
                designSize: Size(400, 300),
                minScale: 1.5,
                enableDesktopScaling: true,
              ),
              child: MaterialApp(
                navigatorKey: navigator,
                home: Builder(
                  builder: (context) {
                    metrics = ScreenSizeAdapter.of(context);
                    return Scaffold(
                      body: TextField(controller: controller, focusNode: focus),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
      focus.requestFocus();
      await tester.pump();
      final inputState = tester.state(find.byType(EditableText));
      final navState = navigator.currentState;
      expect(metrics.scale, 2);
      rebuild(() => enabled = false);
      await tester.pump();
      expect(metrics.scale, 1);
      expect(metrics.designSize, const Size(800, 600));
      expect(metrics.assetDpr, 2);
      expect(tester.state(find.byType(EditableText)), same(inputState));
      expect(navigator.currentState, same(navState));
      expect(focus.hasFocus, isTrue);
      expect(controller.text, 'keep me');
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Second route')),
        ),
      );
      await tester.pumpAndSettle();
      rebuild(() => enabled = true);
      await tester.pumpAndSettle();
      expect(find.text('Second route'), findsOneWidget);
      expect(navigator.currentState, same(navState));
    },
  );

  testWidgets('metrics outside adapter are native and resize reactively', (
    tester,
  ) async {
    nativeView(tester);
    late Size origin;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          origin = ScreenSizeAdapter.originSizeOf(context);
          expect(ScreenSizeAdapter.scaleOf(context), 1);
          expect(ScreenSizeMetrics.maybeOf(context), isNull);
          expect(() => ScreenSizeMetrics.of(context), throwsFlutterError);
          return const SizedBox();
        },
      ),
    );
    expect(origin, const Size(800, 600));
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    expect(origin, const Size(600, 400));
  });

  testWidgets('rejects partial viewport mounting with actionable error', (
    tester,
  ) async {
    nativeView(tester);
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: ScreenSizeAdapter(
            config: ScreenSizeAdapterConfig(designSize: Size(100, 100)),
            child: SizedBox(),
          ),
        ),
      ),
    );
    expect(tester.takeException().toString(), contains('above MaterialApp'));
  });

  for (final dpr in [1.0, 1.5, 3.0]) {
    testWidgets('native DPR $dpr is independent of adapter scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = const Size(600, 800) * dpr;
      addTearDown(tester.view.reset);
      late ScreenSizeMetrics metrics;
      late MediaQueryData media;
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: const ScreenSizeAdapterConfig(
            designSize: Size(400, 800),
            enableDesktopScaling: true,
          ),
          child: Builder(
            builder: (context) {
              metrics = ScreenSizeAdapter.of(context);
              media = MediaQuery.of(context);
              expect(
                ScreenSizeAdapter.originSizeOf(context),
                metrics.originSize,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(metrics.scale, 1.5);
      expect(metrics.nativeDpr, dpr);
      expect(media.devicePixelRatio, dpr * 1.5);
      expect(
        tester.binding.renderViews.single.configuration.devicePixelRatio,
        dpr,
      );
      tester.view.devicePixelRatio = dpr * 2;
      await tester.pump();
      expect(metrics.scale, 0.75);
      expect(metrics.nativeDpr, dpr * 2);
      expect(
        tester.binding.renderViews.single.configuration.devicePixelRatio,
        dpr * 2,
      );
    });
  }
}
