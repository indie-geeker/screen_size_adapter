import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';
import 'package:screen_size_adapter/src/internal/adapter_metrics.dart';

void main() {
  testWidgets('originSizeOf returns the unscaled FlutterView logical size', (
    tester,
  ) async {
    // tester.view exposes a TestFlutterView whose physicalSize/dpr we can set.
    // 1440x2760 / 2.0 = 720x1380 unscaled logical — twice the designSize
    // (360x690), so the scaling layer would compress MediaQuery to 360 but
    // originSizeOf must still report 720.
    tester.view.physicalSize = const Size(1440, 2760);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Size? originObserved;
    Size? mediaQueryObserved;
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        child: Builder(
          builder: (ctx) {
            originObserved = ScreenSizeAdapter.originSizeOf(ctx);
            mediaQueryObserved = MediaQuery.sizeOf(ctx);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Native logical size — usable for breakpoints.
    expect(originObserved, const Size(720, 1380));
    // Design size — what MediaQuery returns under the scope.
    expect(mediaQueryObserved, const Size(360, 690));
  });
  testWidgets('origin-only reader reacts to native view resize', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.reset);
    Size? observed;
    final reader = Builder(
      builder: (context) {
        observed = ScreenSizeAdapter.originSizeOf(context);
        return const SizedBox.shrink();
      },
    );
    await tester.pumpWidget(reader);
    expect(observed, const Size(400, 600));
    tester.view.physicalSize = const Size(1600, 2400);
    await tester.pump();
    expect(observed, const Size(800, 1200));
  });
  testWidgets(
    'native metric snapshot notifies through an unchanged MediaQuery',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);
      Size? observed;
      final reader = Builder(
        builder: (context) {
          observed = ScreenSizeAdapter.originSizeOf(context);
          return const SizedBox.shrink();
        },
      );
      Widget scene() => MediaQuery(
        data: const MediaQueryData(size: Size(200, 300)),
        child: AdapterMetrics(
          viewId: tester.view.viewId,
          originSize: tester.view.physicalSize / tester.view.devicePixelRatio,
          scale: 2,
          child: reader,
        ),
      );
      await tester.pumpWidget(scene());
      expect(observed, const Size(400, 600));
      tester.view.physicalSize = const Size(1600, 2400);
      await tester.pumpWidget(scene());
      expect(observed, const Size(800, 1200));
    },
  );

  testWidgets('origin reader sees native resize before scope rebuild', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.reset);
    late BuildContext context;
    await tester.pumpWidget(
      AdapterMetrics(
        viewId: tester.view.viewId,
        originSize: const Size(400, 600),
        scale: 2,
        child: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    tester.view.physicalSize = const Size(1600, 2400);
    expect(ScreenSizeAdapter.originSizeOf(context), const Size(800, 1200));
  });

  testWidgets('metrics from another view cannot override the current origin', (
    tester,
  ) async {
    Size? observed;
    await tester.pumpWidget(
      AdapterMetrics(
        viewId: tester.view.viewId + 100,
        originSize: const Size(1, 1),
        scale: 10,
        child: Builder(
          builder: (context) {
            observed = ScreenSizeAdapter.originSizeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(observed, tester.view.physicalSize / tester.view.devicePixelRatio);
  });
}
