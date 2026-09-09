import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'root_viewport_test.dart' show nativeView;

ScreenSizeAdapterConfig configAt(double scale) => ScreenSizeAdapterConfig(
  designSize: const Size(800, 600) / scale,
  enableDesktopScaling: true,
);

void main() {
  for (final scale in [0.5, 1.0, 1.25, 2.0, 3.0]) {
    testWidgets('full viewport hits and local coordinates at scale $scale', (
      tester,
    ) async {
      nativeView(tester);
      final positions = <Offset>[];
      final globals = <Offset>[];
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: configAt(scale),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                positions.add(e.localPosition);
                globals.add(e.position);
              },
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      for (final point in [
        const Offset(1, 1),
        const Offset(799, 1),
        const Offset(1, 599),
        const Offset(799, 599),
      ]) {
        await tester.tapAt(point);
        expect(globals.last, point);
        expect((positions.last - point / scale).distance, lessThan(0.001));
      }
      expect(positions.length, 4);
      await tester.tapAt(const Offset(801, 300));
      expect(positions.length, 4);
    });

    testWidgets('native drag slop and design scroll delta at scale $scale', (
      tester,
    ) async {
      nativeView(tester);
      var starts = 0;
      final deltas = <double>[];
      await tester.pumpWidget(
        Builder(
          builder:
              (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  gestureSettings: const DeviceGestureSettings(touchSlop: 18),
                ),
                child: ScreenSizeAdapter(
                  config: configAt(scale),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    onVerticalDragStart: (_) => starts++,
                    onVerticalDragUpdate:
                        (details) => deltas.add(details.delta.dy),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
        ),
      );
      final drag = await tester.startGesture(const Offset(200, 200));
      await drag.moveBy(const Offset(0, 12));
      expect(starts, 0, reason: '12 native units must remain below 18 slop');
      await drag.moveBy(const Offset(0, 10));
      expect(starts, 1, reason: '22 native units must cross 18 slop');
      await drag.moveBy(const Offset(0, 40));
      expect(deltas.last, closeTo(40 / scale, 0.001));
      await drag.up();
    });

    testWidgets('ListView scroll and wheel remain usable at scale $scale', (
      tester,
    ) async {
      nativeView(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: configAt(scale),
          child: MaterialApp(
            home: ListView.builder(
              controller: scroll,
              itemExtent: 50,
              itemCount: 200,
              itemBuilder: (context, i) => Text('row $i'),
            ),
          ),
        ),
      );
      final drag = await tester.startGesture(const Offset(200, 350));
      await drag.moveBy(const Offset(0, -30));
      final before = scroll.offset;
      await drag.moveBy(const Offset(0, -80));
      expect(scroll.offset - before, closeTo(80 / scale, 0.001));
      await drag.up();
      await tester.pumpAndSettle();
      final beforeWheel = scroll.offset;
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(200, 300),
          scrollDelta: Offset(0, 60),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(beforeWheel));
      // Record rather than falsely asserting wheel deltas are transformed.
      debugPrint(
        'wheel scale=$scale design delta=${scroll.offset - beforeWheel}',
      );
    });
  }

  for (final axis in ScaleAxis.values) {
    testWidgets('orientation and clamp geometry ${axis.name}', (tester) async {
      nativeView(tester);
      const design = Size(360, 690);
      final config = ScreenSizeAdapterConfig(
        designSize: design,
        scaleAxis: axis,
        minScale: 0.75,
        maxScale: 1.5,
        enableDesktopScaling: true,
      );
      Size? layout;
      MediaQueryData? mq;
      final child = Builder(
        builder: (context) {
          mq = MediaQuery.of(context);
          return LayoutBuilder(
            builder: (context, c) {
              layout = c.biggest;
              return const SizedBox.expand();
            },
          );
        },
      );
      await tester.pumpWidget(ScreenSizeAdapter(config: config, child: child));
      for (final origin in [
        const Size(800, 600),
        const Size(390, 844),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = origin * 2;
        await tester.pump();
        final scale = ScreenSizeAdapter.computeScale(
          origin: origin,
          config: config,
          isDesktop: false,
        );
        expect(layout!.width, closeTo(origin.width / scale, 0.001));
        expect(layout!.height, closeTo(origin.height / scale, 0.001));
        expect(mq!.size, layout);
      }
    });
  }

  testWidgets(
    'metrics-only consumers rebuild on native resize with unchanged design size',
    (tester) async {
      nativeView(tester, size: const Size(400, 800));
      ScreenSizeMetrics? metrics;
      var builds = 0;
      final child = Builder(
        builder: (context) {
          metrics = ScreenSizeMetrics.of(context);
          builds++;
          return const SizedBox.expand();
        },
      );
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: const ScreenSizeAdapterConfig(
            designSize: Size(400, 800),
            enableDesktopScaling: true,
          ),
          child: child,
        ),
      );
      expect(metrics!.scale, 1);
      tester.view.physicalSize = const Size(1600, 3200);
      await tester.pump();
      expect(metrics!.originSize, const Size(800, 1600));
      expect(metrics!.scale, 2);
      expect(metrics!.designSize, const Size(400, 800));
      expect(builds, 2);
    },
  );

  testWidgets(
    'identity boundary preserves focus, text, state and scale subscribers',
    (tester) async {
      nativeView(tester);
      final configs = ValueNotifier(configAt(2));
      final controller = TextEditingController(text: 'preserve');
      final focus = FocusNode();
      addTearDown(configs.dispose);
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      double? observed;
      final child = MaterialApp(
        home: Builder(
          builder: (context) {
            observed = ScreenSizeMetrics.of(context).scale;
            return Scaffold(
              body: TextField(controller: controller, focusNode: focus),
            );
          },
        ),
      );
      await tester.pumpWidget(
        ValueListenableBuilder<ScreenSizeAdapterConfig>(
          valueListenable: configs,
          builder:
              (context, config, _) =>
                  ScreenSizeAdapter(config: config, child: child),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      final state = tester.state(find.byType(EditableText));
      for (final scale in [1.0, 0.5, 3.0]) {
        configs.value = configAt(scale);
        await tester.pump();
        expect(observed, scale);
        expect(tester.state(find.byType(EditableText)), same(state));
        expect(focus.hasFocus, isTrue);
        expect(controller.text, 'preserve');
      }
    },
  );

  testWidgets('safe area, keyboard and asset DPR use design geometry', (
    tester,
  ) async {
    nativeView(tester);
    MediaQueryData? media;
    ImageConfiguration? imageConfig;
    final key = GlobalKey();
    await tester.pumpWidget(
      Builder(
        builder:
            (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 40),
                viewPadding: const EdgeInsets.only(top: 40),
                viewInsets: const EdgeInsets.only(bottom: 200),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: ScreenSizeAdapter(
                config: configAt(2),
                child: MaterialApp(
                  home: Builder(
                    builder: (context) {
                      media = MediaQuery.of(context);
                      imageConfig = createLocalImageConfiguration(context);
                      return Scaffold(
                        body: SafeArea(child: SizedBox.expand(key: key)),
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
    expect(media!.padding.top, 20);
    expect(media!.viewInsets.bottom, 100);
    expect(media!.textScaler.scale(20), 30);
    expect(imageConfig!.devicePixelRatio, 4);
    expect(tester.getTopLeft(find.byKey(key)), const Offset(0, 40));
    expect(tester.getBottomRight(find.byKey(key)), const Offset(800, 400));
  });

  testWidgets('overlay follower includes scale exactly once', (tester) async {
    nativeView(tester);
    final link = LayerLink();
    final anchor = GlobalKey();
    final follower = GlobalKey();
    late BuildContext ctx;
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: configAt(2),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return Stack(
                children: [
                  Positioned(
                    left: 40,
                    top: 60,
                    child: CompositedTransformTarget(
                      link: link,
                      child: SizedBox(key: anchor, width: 100, height: 30),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    final overlay = OverlayEntry(
      builder:
          (_) => Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: link,
              offset: const Offset(0, 30),
              child: SizedBox(key: follower, width: 100, height: 20),
            ),
          ),
    );
    Overlay.of(ctx).insert(overlay);
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(anchor)), const Offset(80, 120));
    expect(tester.getTopLeft(find.byKey(follower)), const Offset(80, 180));
    overlay.remove();
    overlay.dispose();
    await tester.pump();
    showDialog<void>(
      context: ctx,
      builder:
          (_) => const AlertDialog(
            title: Text('dialog'),
            content: Text('inside root'),
          ),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byType(AlertDialog)).dx, closeTo(400, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics carries the design-to-native scale', (tester) async {
    nativeView(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: configAt(2),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned(
                left: 40,
                top: 60,
                child: Semantics(
                  label: 'target',
                  button: true,
                  onTap: () {},
                  child: const SizedBox(width: 100, height: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('target'));
    var rect = node.rect;
    var current = node;
    while (true) {
      if (current.transform != null) {
        rect = MatrixUtils.transformRect(current.transform!, rect);
      }
      final parent = current.parent;
      if (parent == null) break;
      current = parent;
    }
    // This traversal includes the root semantics transform: design -> native -> physical.
    expect(rect, const Rect.fromLTWH(160, 240, 400, 200));
    handle.dispose();
  });

  testWidgets('same-view nesting produces a clear diagnostic', (tester) async {
    nativeView(tester);
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: configAt(2),
        child: ScreenSizeAdapter(
          config: configAt(2),
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(tester.takeException().toString(), contains('once per FlutterView'));
  });
}
